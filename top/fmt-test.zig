const fmt = @import("./fmt.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const proc = @import("./proc.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub const is_correct: bool = true;

pub usingnamespace proc.start;

fn testEquivalentIntToString() !void {
    var uint: u64 = 0;
    while (uint != 0x10000) : (uint += 1) {
        const uint_32: u32 = @truncate(u32, uint);
        const uint_16: u16 = @truncate(u16, uint);
        const uint_8: u8 = @truncate(u8, uint);
        const sint_64: i64 = @bitReverse(@bitCast(i64, uint));
        const sint_32: i32 = @bitReverse(@bitCast(i32, @truncate(u32, uint)));
        const sint_16: i16 = @bitReverse(@bitCast(i16, @truncate(u16, uint)));
        const sint_8: i8 = @bitReverse(@bitCast(i8, @truncate(u8, uint)));
        try testing.expectEqualMany(u8, builtin.fmt.ub64(uint).readAll(), fmt.ub64(uint).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ub32(uint_32).readAll(), fmt.ub32(uint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ub16(uint_16).readAll(), fmt.ub16(uint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ub8(uint_8).readAll(), fmt.ub8(uint_8).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.uo64(uint).readAll(), fmt.uo64(uint).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.uo32(uint_32).readAll(), fmt.uo32(uint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.uo16(uint_16).readAll(), fmt.uo16(uint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.uo8(uint_8).readAll(), fmt.uo8(uint_8).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ud64(uint).readAll(), fmt.ud64(uint).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ud32(uint_32).readAll(), fmt.ud32(uint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ud16(uint_16).readAll(), fmt.ud16(uint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ud8(uint_8).readAll(), fmt.ud8(uint_8).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ux64(uint).readAll(), fmt.ux64(uint).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ux32(uint_32).readAll(), fmt.ux32(uint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ux16(uint_16).readAll(), fmt.ux16(uint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ux8(uint_8).readAll(), fmt.ux8(uint_8).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ib64(sint_64).readAll(), fmt.ib64(sint_64).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ib32(sint_32).readAll(), fmt.ib32(sint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ib16(sint_16).readAll(), fmt.ib16(sint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ib8(sint_8).readAll(), fmt.ib8(sint_8).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.io64(sint_64).readAll(), fmt.io64(sint_64).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.io32(sint_32).readAll(), fmt.io32(sint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.io16(sint_16).readAll(), fmt.io16(sint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.io8(sint_8).readAll(), fmt.io8(sint_8).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.id64(sint_64).readAll(), fmt.id64(sint_64).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.id32(sint_32).readAll(), fmt.id32(sint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.id16(sint_16).readAll(), fmt.id16(sint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.id8(sint_8).readAll(), fmt.id8(sint_8).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ix64(sint_64).readAll(), fmt.ix64(sint_64).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ix32(sint_32).readAll(), fmt.ix32(sint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ix16(sint_16).readAll(), fmt.ix16(sint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ix8(sint_8).readAll(), fmt.ix8(sint_8).formatConvert().readAll());
    }
}
pub fn main() !void {
    try meta.wrap(testEquivalentIntToString());
}
