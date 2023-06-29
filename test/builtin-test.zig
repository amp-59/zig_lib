const zig_lib = @import("../zig_lib.zig");
const proc = zig_lib.proc;
const builtin = zig_lib.builtin;
const testing = zig_lib.testing;

pub usingnamespace proc.start;

pub const runtime_assertions: bool = true;
pub const comptime_assertions: bool = true;

pub fn comptimeIntToStringNoob(comptime value: comptime_int) []const u8 {
    var s: []const u8 = "";
    var y = if (value < 0) -value else value;
    while (y != 0) : (y /= 10) {
        s = s ++ [1]u8{(y % 10) + 48};
    }
    return if (value < 0) "-" ++ s else s;
}
pub fn comptimeIntToStringPro(comptime value: comptime_int) []const u8 {
    if (value < 0) {
        const s: []const u8 = @typeName([-value]void);
        return "-" ++ s[1 .. s.len - 5];
    } else {
        const s: []const u8 = @typeName([value]void);
        return s[1 .. s.len - 5];
    }
}
pub fn testComptimeIntToString() void {
    @setEvalBranchQuota(0x10000);
    inline for (0x0..0x10000) |index| {
        _ = comptime comptimeIntToStringPro(index);
    }
}
pub fn testIntToString() !void {
    const T: type = u64;
    var arg1: T = 0;
    var iint: i64 = -0xfee1dead;
    try testing.expectEqualMany(u8, builtin.fmt.ix64(iint).readAll(), "-0xfee1dead");
    iint = -0x0;
    try testing.expectEqualMany(u8, builtin.fmt.ix64(iint).readAll(), "0x0");
    var uint: u64 = 0xdeadbeef;
    try testing.expectEqualMany(u8, builtin.fmt.ux64(uint).readAll(), "0xdeadbeef");
    const bs: [2]bool = .{ true, false };
    for (bs) |b_0| {
        builtin.assertEqual(u64, @intFromBool(b_0), builtin.int(u64, b_0));
        for (bs) |b_1| {
            builtin.assertEqual(u64, @intFromBool(b_0 or b_1), builtin.int2v(u64, b_0, b_1));
            builtin.assertEqual(u64, @intFromBool(b_0 and b_1), builtin.int2a(u64, b_0, b_1));
            for (bs) |b_2| {
                builtin.assertEqual(u64, @intFromBool(b_0 or b_1 or b_2), builtin.int3v(u64, b_0, b_1, b_2));
                builtin.assertEqual(u64, @intFromBool(b_0 and b_1 and b_2), builtin.int3a(u64, b_0, b_1, b_2));
            }
        }
    }
    try testing.expectEqualMany(u8, builtin.fmt.ub8(0).readAll(), "0b00000000");
    try testing.expectEqualMany(u8, builtin.fmt.ub8(1).readAll(), "0b00000001");
    const start = @intFromPtr(&arg1);
    var inc: u64 = 1;
    uint = start;
    while (uint - start < 0x100000) : ({
        uint +%= inc;
        inc +%= 1;
    }) {
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
    iint = @bitCast(isize, start);
    inc = 1;
    while (iint < 0x100000) : ({
        uint +%= inc;
        inc +%= 1;
    }) {
        builtin.assertEqual(i64, iint, builtin.parse.ib(i64, builtin.fmt.ib64(iint).readAll()));
        builtin.assertEqual(i64, iint, builtin.parse.io(i64, builtin.fmt.io64(iint).readAll()));
        builtin.assertEqual(i64, iint, builtin.parse.id(i64, builtin.fmt.id64(iint).readAll()));
        builtin.assertEqual(i64, iint, builtin.parse.ix(i64, builtin.fmt.ix64(iint).readAll()));
        builtin.assertEqual(i32, @truncate(i32, iint), builtin.parse.ib(i32, builtin.fmt.ib32(@truncate(i32, iint)).readAll()));
        builtin.assertEqual(i32, @truncate(i32, iint), builtin.parse.io(i32, builtin.fmt.io32(@truncate(i32, iint)).readAll()));
        builtin.assertEqual(i32, @truncate(i32, iint), builtin.parse.id(i32, builtin.fmt.id32(@truncate(i32, iint)).readAll()));
        builtin.assertEqual(i32, @truncate(i32, iint), builtin.parse.ix(i32, builtin.fmt.ix32(@truncate(i32, iint)).readAll()));
        builtin.assertEqual(i16, @truncate(i16, iint), builtin.parse.ib(i16, builtin.fmt.ib16(@truncate(i16, iint)).readAll()));
        builtin.assertEqual(i16, @truncate(i16, iint), builtin.parse.io(i16, builtin.fmt.io16(@truncate(i16, iint)).readAll()));
        builtin.assertEqual(i16, @truncate(i16, iint), builtin.parse.id(i16, builtin.fmt.id16(@truncate(i16, iint)).readAll()));
        builtin.assertEqual(i16, @truncate(i16, iint), builtin.parse.ix(i16, builtin.fmt.ix16(@truncate(i16, iint)).readAll()));
        builtin.assertEqual(i8, @truncate(i8, iint), builtin.parse.ib(i8, builtin.fmt.ib8(@truncate(i8, iint)).readAll()));
        builtin.assertEqual(i8, @truncate(i8, iint), builtin.parse.io(i8, builtin.fmt.io8(@truncate(i8, iint)).readAll()));
        builtin.assertEqual(i8, @truncate(i8, iint), builtin.parse.id(i8, builtin.fmt.id8(@truncate(i8, iint)).readAll()));
        builtin.assertEqual(i8, @truncate(i8, iint), builtin.parse.ix(i8, builtin.fmt.ix8(@truncate(i8, iint)).readAll()));
        try builtin.expectEqual(i64, iint, builtin.parse.ib(i64, builtin.fmt.ib64(iint).readAll()));
        try builtin.expectEqual(i64, iint, builtin.parse.io(i64, builtin.fmt.io64(iint).readAll()));
        try builtin.expectEqual(i64, iint, builtin.parse.id(i64, builtin.fmt.id64(iint).readAll()));
        try builtin.expectEqual(i64, iint, builtin.parse.ix(i64, builtin.fmt.ix64(iint).readAll()));
        try builtin.expectEqual(i32, @truncate(i32, iint), builtin.parse.ib(i32, builtin.fmt.ib32(@truncate(i32, iint)).readAll()));
        try builtin.expectEqual(i32, @truncate(i32, iint), builtin.parse.io(i32, builtin.fmt.io32(@truncate(i32, iint)).readAll()));
        try builtin.expectEqual(i32, @truncate(i32, iint), builtin.parse.id(i32, builtin.fmt.id32(@truncate(i32, iint)).readAll()));
        try builtin.expectEqual(i32, @truncate(i32, iint), builtin.parse.ix(i32, builtin.fmt.ix32(@truncate(i32, iint)).readAll()));
        try builtin.expectEqual(i16, @truncate(i16, iint), builtin.parse.ib(i16, builtin.fmt.ib16(@truncate(i16, iint)).readAll()));
        try builtin.expectEqual(i16, @truncate(i16, iint), builtin.parse.io(i16, builtin.fmt.io16(@truncate(i16, iint)).readAll()));
        try builtin.expectEqual(i16, @truncate(i16, iint), builtin.parse.id(i16, builtin.fmt.id16(@truncate(i16, iint)).readAll()));
        try builtin.expectEqual(i16, @truncate(i16, iint), builtin.parse.ix(i16, builtin.fmt.ix16(@truncate(i16, iint)).readAll()));
        try builtin.expectEqual(i8, @truncate(i8, iint), builtin.parse.ib(i8, builtin.fmt.ib8(@truncate(i8, iint)).readAll()));
        try builtin.expectEqual(i8, @truncate(i8, iint), builtin.parse.io(i8, builtin.fmt.io8(@truncate(i8, iint)).readAll()));
        try builtin.expectEqual(i8, @truncate(i8, iint), builtin.parse.id(i8, builtin.fmt.id8(@truncate(i8, iint)).readAll()));
        try builtin.expectEqual(i8, @truncate(i8, iint), builtin.parse.ix(i8, builtin.fmt.ix8(@truncate(i8, iint)).readAll()));
    }
}
fn expectVersionEqual(text: []const u8, v1: u32, v2: u32, v3: u32) !void {
    const v = try builtin.Version.parseVersion(text);
    builtin.assertEqual(u32, v.major, v1);
    builtin.assertEqual(u32, v.minor, v2);
    builtin.assertEqual(u32, v.patch, v3);
}
fn expectVersionError(text: []const u8, expected_err: anyerror) !void {
    _ = builtin.Version.parseVersion(text) catch |actual_err| {
        if (actual_err == expected_err) return;
        return actual_err;
    };
    return error.Unreachable;
}
fn testVersionParser() !void {
    try expectVersionEqual("2.6.32.11-svn21605", 2, 6, 32); // Debian PPC
    try expectVersionEqual("2.11.2(0.329/5/3)", 2, 11, 2); // MinGW
    try expectVersionEqual("5.4.0-1018-raspi", 5, 4, 0); // Ubuntu
    try expectVersionEqual("5.7.12_3", 5, 7, 12); // Void
    try expectVersionEqual("2.13-DEVELOPMENT", 2, 13, 0); // DragonFly
    try expectVersionEqual("2.3-35", 2, 3, 0);
    try expectVersionEqual("1a.4", 1, 0, 0);
    try expectVersionEqual("3.b1.0", 3, 0, 0);
    try expectVersionEqual("1.4beta", 1, 4, 0);
    try expectVersionEqual("2.7.pre", 2, 7, 0);
    try expectVersionEqual("0..3", 0, 0, 0);
    try expectVersionEqual("8.008.", 8, 8, 0);
    try expectVersionEqual("01...", 1, 0, 0);
    try expectVersionEqual("55", 55, 0, 0);
    try expectVersionEqual("4294967295.0.1", 4294967295, 0, 1);
    try expectVersionEqual("429496729_6", 429496729, 0, 0);
    try expectVersionError("foobar", error.InvalidVersion);
    try expectVersionError("", error.InvalidVersion);
    try expectVersionError("-1", error.InvalidVersion);
    try expectVersionError("+4", error.InvalidVersion);
    try expectVersionError(".", error.InvalidVersion);
    try expectVersionError("....3", error.InvalidVersion);
    try expectVersionError("4294967296", error.Overflow);
    try expectVersionError("5000877755", error.Overflow);
}
fn testRuntimeAssertionsCompile() !void {
    const T: type = u64;
    var b: bool = true;
    var arg1: T = 0;
    var arg2: T = 1;
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
pub fn testStaticAssertionsCompile() !void {
    const T: type = u64;
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
}
fn testMinMax() !void {
    const S = extern struct {
        a: u64 = 0,
        b: u64 = 0,
    };
    const s: S = .{ .a = 50, .b = 25 };
    const t: S = .{ .a = 25, .b = 50 };
    try builtin.expect(builtin.testEqual(u64, s.b, builtin.min(u64, s.a, s.b)));
    try builtin.expect(builtin.testEqual(u64, t.b, builtin.max(u64, t.b, t.a)));
    try builtin.expect(builtin.testEqual(S, s, builtin.min(S, t, s)));
    try builtin.expect(builtin.testEqual(S, t, builtin.max(S, t, s)));
}
pub fn main() !void {
    try testIntToString();
    try testVersionParser();
    try testRuntimeAssertionsCompile();
    try testStaticAssertionsCompile();
    try testMinMax();
    builtin.debug.sampleAllReports();
}
