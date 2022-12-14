const builtin = @import("./builtin.zig");
const proc = @import("./proc.zig");

pub usingnamespace proc.start;

pub const is_correct: bool = true;

// TODO: Tests to show all error messages.
export fn showAssertionFailedAbove(arg1: u64, arg2: u64) void {
    builtin.assertAbove(u64, arg1, arg2);
}
export fn showAssertionFailedAboveOrEqual(arg1: u64, arg2: u64) void {
    builtin.assertAboveOrEqual(u64, arg1, arg2);
}
export fn showAssertionFailedEqual(arg1: u64, arg2: u64) void {
    builtin.assertEqual(u64, arg1, arg2);
}
export fn showAssertionFailedBelow(arg1: u64, arg2: u64) void {
    builtin.assertBelow(u64, arg1, arg2);
}
export fn showAssertionFailedBelowOrEqual(arg1: u64, arg2: u64) void {
    builtin.assertBelowOrEqual(u64, arg1, arg2);
}
export fn showAssertionFailedNotEqual(arg1: u64, arg2: u64) void {
    builtin.assertNotEqual(u64, arg1, arg2);
}

pub fn main() !void {
    const T: type = u64;
    var arg1: T = 0;
    var arg2: T = 1;
    var b: bool = true;
    var iint: i64 = -0x1fee1dead;
    for (builtin.fmt.ux(i64, iint).readAll()) |c, i| {
        builtin.assertEqual(u8, "-0x1fee1dead"[i], c);
    }
    iint = -0x0;
    for (builtin.fmt.ux(i64, iint).readAll()) |c, i| {
        builtin.assertEqual(u8, "0x0"[i], c);
    }
    var uint: u64 = 0xdeadbeef;
    for (builtin.fmt.ux64(uint).readAll()) |c, i| {
        builtin.assertEqual(u8, "0xdeadbeef"[i], c);
    }
    const bs: [2]bool = .{ true, false };
    for (bs) |b_0| {
        builtin.assertEqual(u64, @boolToInt(b_0), builtin.int(u64, b_0));
        for (bs) |b_1| {
            builtin.assertEqual(u64, @boolToInt(b_0 or b_1), builtin.int2v(u64, b_0, b_1));
            builtin.assertEqual(u64, @boolToInt(b_0 and b_1), builtin.int2a(u64, b_0, b_1));
            for (bs) |b_2| {
                builtin.assertEqual(u64, @boolToInt(b_0 or b_1 or b_2), builtin.int3v(u64, b_0, b_1, b_2));
                builtin.assertEqual(u64, @boolToInt(b_0 and b_1 and b_2), builtin.int3a(u64, b_0, b_1, b_2));
            }
        }
    }
    for (builtin.fmt.ub(u1, 0).readAll()) |c, i| {
        builtin.assertEqual(u8, "0b0"[i], c);
    }
    for (builtin.fmt.ub(u1, 1).readAll()) |c, i| {
        builtin.assertEqual(u8, "0b1"[i], c);
    }
    uint = 1;
    while (uint < 0x100000) : (uint += 99) {
        builtin.assertEqual(u64, uint, builtin.parse.ub(u64, builtin.fmt.ub64(uint).readAll()));
        builtin.assertEqual(u64, uint, builtin.parse.uo(u64, builtin.fmt.uo64(uint).readAll()));
        builtin.assertEqual(u64, uint, builtin.parse.ud(u64, builtin.fmt.ud64(uint).readAll()));
        builtin.assertEqual(u64, uint, builtin.parse.ux(u64, builtin.fmt.ux64(uint).readAll()));
        builtin.assertEqual(u32, @truncate(u32, uint), builtin.parse.ub(u32, builtin.fmt.ub32(@truncate(u32, uint)).readAll()));
        builtin.assertEqual(u32, @truncate(u32, uint), builtin.parse.uo(u32, builtin.fmt.uo32(@truncate(u32, uint)).readAll()));
        builtin.assertEqual(u32, @truncate(u32, uint), builtin.parse.ud(u32, builtin.fmt.ud32(@truncate(u32, uint)).readAll()));
        builtin.assertEqual(u32, @truncate(u32, uint), builtin.parse.ux(u32, builtin.fmt.ux32(@truncate(u32, uint)).readAll()));
        builtin.assertEqual(u16, @truncate(u16, uint), builtin.parse.ub(u16, builtin.fmt.ub16(@truncate(u16, uint)).readAll()));
        builtin.assertEqual(u16, @truncate(u16, uint), builtin.parse.uo(u16, builtin.fmt.uo16(@truncate(u16, uint)).readAll()));
        builtin.assertEqual(u16, @truncate(u16, uint), builtin.parse.ud(u16, builtin.fmt.ud16(@truncate(u16, uint)).readAll()));
        builtin.assertEqual(u16, @truncate(u16, uint), builtin.parse.ux(u16, builtin.fmt.ux16(@truncate(u16, uint)).readAll()));
        builtin.assertEqual(u8, @truncate(u8, uint), builtin.parse.ub(u8, builtin.fmt.ub8(@truncate(u8, uint)).readAll()));
        builtin.assertEqual(u8, @truncate(u8, uint), builtin.parse.uo(u8, builtin.fmt.uo8(@truncate(u8, uint)).readAll()));
        builtin.assertEqual(u8, @truncate(u8, uint), builtin.parse.ud(u8, builtin.fmt.ud8(@truncate(u8, uint)).readAll()));
        builtin.assertEqual(u8, @truncate(u8, uint), builtin.parse.ux(u8, builtin.fmt.ux8(@truncate(u8, uint)).readAll()));
        try builtin.expectEqual(u64, uint, builtin.parse.ub(u64, builtin.fmt.ub64(uint).readAll()));
        try builtin.expectEqual(u64, uint, builtin.parse.uo(u64, builtin.fmt.uo64(uint).readAll()));
        try builtin.expectEqual(u64, uint, builtin.parse.ud(u64, builtin.fmt.ud64(uint).readAll()));
        try builtin.expectEqual(u64, uint, builtin.parse.ux(u64, builtin.fmt.ux64(uint).readAll()));
        try builtin.expectEqual(u32, @truncate(u32, uint), builtin.parse.ub(u32, builtin.fmt.ub32(@truncate(u32, uint)).readAll()));
        try builtin.expectEqual(u32, @truncate(u32, uint), builtin.parse.uo(u32, builtin.fmt.uo32(@truncate(u32, uint)).readAll()));
        try builtin.expectEqual(u32, @truncate(u32, uint), builtin.parse.ud(u32, builtin.fmt.ud32(@truncate(u32, uint)).readAll()));
        try builtin.expectEqual(u32, @truncate(u32, uint), builtin.parse.ux(u32, builtin.fmt.ux32(@truncate(u32, uint)).readAll()));
        try builtin.expectEqual(u16, @truncate(u16, uint), builtin.parse.ub(u16, builtin.fmt.ub16(@truncate(u16, uint)).readAll()));
        try builtin.expectEqual(u16, @truncate(u16, uint), builtin.parse.uo(u16, builtin.fmt.uo16(@truncate(u16, uint)).readAll()));
        try builtin.expectEqual(u16, @truncate(u16, uint), builtin.parse.ud(u16, builtin.fmt.ud16(@truncate(u16, uint)).readAll()));
        try builtin.expectEqual(u16, @truncate(u16, uint), builtin.parse.ux(u16, builtin.fmt.ux16(@truncate(u16, uint)).readAll()));
        try builtin.expectEqual(u8, @truncate(u8, uint), builtin.parse.ub(u8, builtin.fmt.ub8(@truncate(u8, uint)).readAll()));
        try builtin.expectEqual(u8, @truncate(u8, uint), builtin.parse.uo(u8, builtin.fmt.uo8(@truncate(u8, uint)).readAll()));
        try builtin.expectEqual(u8, @truncate(u8, uint), builtin.parse.ud(u8, builtin.fmt.ud8(@truncate(u8, uint)).readAll()));
        try builtin.expectEqual(u8, @truncate(u8, uint), builtin.parse.ux(u8, builtin.fmt.ux8(@truncate(u8, uint)).readAll()));
    }
    _ = builtin.lib_build_root;
    // Testing compilation
    comptime {
        var static_arg1: T = 0;
        var static_arg2: T = 2;
        var static_b: bool = true;
        static_arg1 = builtin.static.add(T, static_arg1, static_arg2);
        builtin.static.addEqu(T, &static_arg1, static_arg2);
        static_arg1 = builtin.static.sub(T, static_arg1, static_arg2);
        builtin.static.subEqu(T, &static_arg1, static_arg2);
        static_arg1 = builtin.static.mul(T, static_arg1, static_arg2);
        builtin.static.mulEqu(T, &static_arg1, static_arg2);
        static_arg1 = builtin.static.divExact(T, static_arg1, static_arg2);
        builtin.static.divEquExact(T, &static_arg1, static_arg2);
        builtin.static.assertBelow(T, static_arg1, static_arg2);
        builtin.static.assertBelowOrEqual(T, static_arg1, static_arg2);
        static_arg1 = static_arg2;
        builtin.static.assertEqual(T, static_arg1, static_arg2);
        builtin.static.addEqu(u64, &static_arg1, 1);
        builtin.static.assertAboveOrEqual(T, static_arg1, static_arg2);
        builtin.static.assertAbove(T, static_arg1, static_arg2);
        builtin.static.assert(static_b);
    }

    if (b) return;
    arg2 = builtin.add(T, arg1, arg2);
    arg2 = builtin.addSat(T, arg1, arg2);
    arg2 = builtin.addWrap(T, arg1, arg2);
    builtin.addEqu(T, &arg1, arg2);
    builtin.addEquSat(T, &arg1, arg2);
    builtin.addEquWrap(T, &arg1, arg2);
    arg2 = builtin.addWithOverflow(T, arg1, arg2)[0];
    b = builtin.addEquWithOverflow(T, &arg1, arg2);
    arg2 = builtin.sub(T, arg1, arg2);
    arg2 = builtin.subSat(T, arg1, arg2);
    arg2 = builtin.subWrap(T, arg1, arg2);
    builtin.subEqu(T, &arg1, arg2);
    builtin.subEquSat(T, &arg1, arg2);
    builtin.subEquWrap(T, &arg1, arg2);
    arg2 = builtin.subWithOverflow(T, arg1, arg2)[0];
    b = builtin.subEquWithOverflow(T, &arg1, arg2);
    arg1 = builtin.mul(T, arg1, arg2);
    arg1 = builtin.mulSat(T, arg1, arg2);
    arg1 = builtin.mulWrap(T, arg1, arg2);
    builtin.mulEqu(T, &arg1, arg2);
    builtin.mulEquSat(T, &arg1, arg2);
    builtin.mulEquWrap(T, &arg1, arg2);
    arg1 = builtin.mulWithOverflow(T, arg1, arg2)[0];
    b = builtin.mulEquWithOverflow(T, &arg1, arg2);
    arg1 = builtin.div(T, arg1, arg2);
    builtin.divEqu(T, &arg1, arg2);
    arg1 = builtin.divExact(T, arg1, arg2);
    builtin.divEquExact(T, &arg1, arg2);
    builtin.divEquTrunc(T, &arg1, arg2);
    arg1 = builtin.divTrunc(T, arg1, arg2);
    builtin.divEquFloor(T, &arg1, arg2);
    arg1 = builtin.divFloor(T, arg1, arg2);
    arg1 = builtin.@"and"(T, arg1, arg2);
    builtin.andEqu(T, &arg1, arg2);
    arg1 = builtin.@"or"(T, arg1, arg2);
    builtin.orEqu(T, &arg1, arg2);
    arg1 = builtin.xor(T, arg1, arg2);
    builtin.xorEqu(T, &arg1, arg2);
    arg1 = builtin.shr(T, arg1, arg2);
    builtin.shrEqu(T, &arg1, arg2);
    arg1 = builtin.shrExact(T, arg1, arg2);
    builtin.shrEquExact(T, &arg1, arg2);
    arg1 = builtin.shl(T, arg1, arg2);
    builtin.shlEqu(T, &arg1, arg2);
    arg1 = builtin.shlExact(T, arg1, arg2);
    builtin.shlEquExact(T, &arg1, arg2);
    arg1 = builtin.shlWithOverflow(T, arg1, arg2)[0];
    b = builtin.shlEquWithOverflow(T, &arg1, arg2);
    arg1 = builtin.min(T, arg1, arg2);
    arg1 = builtin.max(T, arg1, arg2);
    builtin.assertBelow(T, arg1, arg2);
    builtin.assertBelowOrEqual(T, arg1, arg2);
    builtin.assertEqual(T, arg1, arg2);
    builtin.assertAboveOrEqual(T, arg1, arg2);
    builtin.assertAbove(T, arg1, arg2);
    builtin.assert(b);
}
