const mem = @import("./mem.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const serial = @import("./serial.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = preset.logging.override.verbose;
pub const runtime_assertions: bool = true;

const AddressSpace = preset.address_space.regular_128;
const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
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

    for (0..0x100) |offset| {
        const s = allocator.save();
        defer allocator.restore(s);
        allocator.ub_addr +%= offset;
        allocator.alignAbove(serial.maxAlignment(S, 0));
        const start = allocator.ub_addr;
        var ss: S = .{
            .t = 25,
            .s = .{ .s = &.{ .s0 = "seven,eight,nine", .s1 = "ten,eleven,twelve,thirteen" } },
            .u = .{ .ss = &.{ "one,two,three", "four,five,six" } },
        };
        const len_0: u64 = serial.length(S, ss);
        const s2 = try meta.wrap(serial.write(&allocator, S, ss));
        const len_1: u64 = serial.length(S, s2);
        builtin.assertEqual(u64, len_0, len_1);
        const x = allocator.ub_addr - start;
        testing.print(.{
            "len_0:\t", len_0, ", len_1:\t", len_1, ", ",
            "x:\t",     x,     '\n',
        });
    }
}
