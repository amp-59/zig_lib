const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const proc = zl.proc;
const debug = zl.debug;
const builtin = zl.builtin;
const testing = zl.testing;

pub usingnamespace zl.start;

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
fn expectVersionEqual(text: []const u8, v1: u32, v2: u32, v3: u32) !void {
    const v = try builtin.Version.parseVersion(text);
    debug.assertEqual(u32, v.major, v1);
    debug.assertEqual(u32, v.minor, v2);
    debug.assertEqual(u32, v.patch, v3);
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
    debug.assertBelow(T, arg1, arg2);
    debug.assertBelowOrEqual(T, arg1, arg2);
    debug.assertEqual(T, arg1, arg2);
    debug.assertAboveOrEqual(T, arg1, arg2);
    debug.assertAbove(T, arg1, arg2);
    debug.assert(b);
}
pub fn testStaticAssertionsCompile() !void {
    const T: type = u64;
    comptime {
        var static_arg1: T = 0;
        var static_arg2: T = 2;
        var static_b: bool = true;
        static_arg1 = builtin.add(T, static_arg1, static_arg2);
        builtin.addEqu(T, &static_arg1, static_arg2);
        static_arg1 = builtin.sub(T, static_arg1, static_arg2);
        builtin.subEqu(T, &static_arg1, static_arg2);
        static_arg1 = builtin.mul(T, static_arg1, static_arg2);
        builtin.mulEqu(T, &static_arg1, static_arg2);
        static_arg1 = builtin.divExact(T, static_arg1, static_arg2);
        builtin.divEquExact(T, &static_arg1, static_arg2);
        debug.assertBelow(T, static_arg1, static_arg2);
        debug.assertBelowOrEqual(T, static_arg1, static_arg2);
        static_arg1 = static_arg2;
        debug.assertEqual(T, static_arg1, static_arg2);
        builtin.addEqu(u64, &static_arg1, 1);
        debug.assertAboveOrEqual(T, static_arg1, static_arg2);
        debug.assertAbove(T, static_arg1, static_arg2);
        debug.assert(static_b);
    }
}
fn testMinMax() !void {
    const S = extern struct {
        a: u64 = 0,
        b: u64 = 0,
    };
    const s: S = .{ .a = 50, .b = 25 };
    const t: S = .{ .a = 25, .b = 50 };
    try debug.expect(mem.testEqual(u64, s.b, builtin.min(u64, s.a, s.b)));
    try debug.expect(mem.testEqual(u64, t.b, builtin.max(u64, t.b, t.a)));
    try debug.expect(mem.testEqual(S, s, builtin.min(S, t, s)));
    try debug.expect(mem.testEqual(S, t, builtin.max(S, t, s)));
}
pub fn main() !void {
    try testVersionParser();
    try testRuntimeAssertionsCompile();
    try testStaticAssertionsCompile();
    try testMinMax();
    debug.sampleAllReports();
}
