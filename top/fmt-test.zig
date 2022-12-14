const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const proc = @import("./proc.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub usingnamespace proc.start;

pub const is_correct: bool = true;

fn testBytesFormat() !void {
    try testing.expectEqualMany(u8, "0B", fmt.bytes(0).formatConvert().readAll());
    try testing.expectEqualMany(u8, "12.224EiB", fmt.bytes(14094246983574119504).formatConvert().readAll());
    try testing.expectEqualMany(u8, "3.055GiB", fmt.bytes(3281572597).formatConvert().readAll());
    try testing.expectEqualMany(u8, "48.898KiB", fmt.bytes(50072).formatConvert().readAll());
    try testing.expectEqualMany(u8, "965.599PiB", fmt.bytes(1087169224958701762).formatConvert().readAll());
    try testing.expectEqualMany(u8, "241.399MiB", fmt.bytes(253126310).formatConvert().readAll());
    try testing.expectEqualMany(u8, "3.771KiB", fmt.bytes(3862).formatConvert().readAll());
    try testing.expectEqualMany(u8, "13.398EiB", fmt.bytes(15448432752139178971).formatConvert().readAll());
    try testing.expectEqualMany(u8, "3.349GiB", fmt.bytes(3596868541).formatConvert().readAll());
    try testing.expectEqualMany(u8, "53.596KiB", fmt.bytes(54883).formatConvert().readAll());
    try testing.expectEqualMany(u8, "15.515EiB", fmt.bytes(17888947792637945813).formatConvert().readAll());
    try testing.expectEqualMany(u8, "3.878GiB", fmt.bytes(4165095228).formatConvert().readAll());
    try testing.expectEqualMany(u8, "62.064KiB", fmt.bytes(63554).formatConvert().readAll());
    try testing.expectEqualMany(u8, "8.527EiB", fmt.bytes(9831702696906455266).formatConvert().readAll());
    try testing.expectEqualMany(u8, "2.131GiB", fmt.bytes(2289121667).formatConvert().readAll());
    try testing.expectEqualMany(u8, "34.110KiB", fmt.bytes(34929).formatConvert().readAll());
    try testing.expectEqualMany(u8, "483.670PiB", fmt.bytes(544565144281564221).formatConvert().readAll());
    try testing.expectEqualMany(u8, "120.916MiB", fmt.bytes(126791453).formatConvert().readAll());
    try testing.expectEqualMany(u8, "1.888KiB", fmt.bytes(1934).formatConvert().readAll());
    try testing.expectEqualMany(u8, "15.571EiB", fmt.bytes(17953561487338746285).formatConvert().readAll());
    try testing.expectEqualMany(u8, "3.892GiB", fmt.bytes(4180139276).formatConvert().readAll());
    try testing.expectEqualMany(u8, "62.288KiB", fmt.bytes(63783).formatConvert().readAll());
    try testing.expectEqualMany(u8, "120.314PiB", fmt.bytes(135462692621452395).formatConvert().readAll());
    try testing.expectEqualMany(u8, "30.078MiB", fmt.bytes(31539865).formatConvert().readAll());
    try testing.expectEqualMany(u8, "481B", fmt.bytes(481).formatConvert().readAll());
    try testing.expectEqualMany(u8, "9.218EiB", fmt.bytes(10629341187628544125).formatConvert().readAll());
    try testing.expectEqualMany(u8, "2.304GiB", fmt.bytes(2474836350).formatConvert().readAll());
    try testing.expectEqualMany(u8, "36.877KiB", fmt.bytes(37763).formatConvert().readAll());
    try testing.expectEqualMany(u8, "3.470EiB", fmt.bytes(4002398647170186451).formatConvert().readAll());
    try testing.expectEqualMany(u8, "888.710MiB", fmt.bytes(931881053).formatConvert().readAll());
    try testing.expectEqualMany(u8, "13.885KiB", fmt.bytes(14219).formatConvert().readAll());
    try testing.expectEqualMany(u8, "10.413EiB", fmt.bytes(12006395527087239748).formatConvert().readAll());
    try testing.expectEqualMany(u8, "2.602GiB", fmt.bytes(2795456798).formatConvert().readAll());
    try testing.expectEqualMany(u8, "41.655KiB", fmt.bytes(42655).formatConvert().readAll());
    try testing.expectEqualMany(u8, "15.978EiB", fmt.bytes(18422768632654111595).formatConvert().readAll());
    try testing.expectEqualMany(u8, "3.994GiB", fmt.bytes(4289385078).formatConvert().readAll());
    try testing.expectEqualMany(u8, "63.916KiB", fmt.bytes(65450).formatConvert().readAll());
    try testing.expectEqualMany(u8, "13.546EiB", fmt.bytes(15619441245434454517).formatConvert().readAll());
    try testing.expectEqualMany(u8, "3.386GiB", fmt.bytes(3636684558).formatConvert().readAll());
    try testing.expectEqualMany(u8, "54.190KiB", fmt.bytes(55491).formatConvert().readAll());
    try testing.expectEqualMany(u8, "13.297EiB", fmt.bytes(15332095086078333874).formatConvert().readAll());
    try testing.expectEqualMany(u8, "3.324GiB", fmt.bytes(3569781567).formatConvert().readAll());
    try testing.expectEqualMany(u8, "53.193KiB", fmt.bytes(54470).formatConvert().readAll());
    try testing.expectEqualMany(u8, "358.001PiB", fmt.bytes(403074625244083568).formatConvert().readAll());
    try testing.expectEqualMany(u8, "89.500MiB", fmt.bytes(93848124).formatConvert().readAll());
    try testing.expectEqualMany(u8, "1.398KiB", fmt.bytes(1432).formatConvert().readAll());
    try testing.expectEqualMany(u8, "5.851EiB", fmt.bytes(6747100094387843530).formatConvert().readAll());
    try testing.expectEqualMany(u8, "1.462GiB", fmt.bytes(1570931657).formatConvert().readAll());
    try testing.expectEqualMany(u8, "23.408KiB", fmt.bytes(23970).formatConvert().readAll());
    try testing.expectEqualMany(u8, "15.999EiB", fmt.bytes(~@as(u64, 0)).formatConvert().readAll());
}
fn testEquivalentIntToStringFormat() !void {
    var uint: u64 = 0;
    while (uint < 0x10000) : (uint += 99) {
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
    try meta.wrap(testEquivalentIntToStringFormat());
    try meta.wrap(testBytesFormat());
}
