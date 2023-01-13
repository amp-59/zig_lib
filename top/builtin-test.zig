const builtin = @import("./builtin.zig");
const proc = @import("./proc.zig");

pub usingnamespace proc.start;

pub const is_correct: bool = true;

fn proper(comptime value: comptime_int) []const u8 {
    var s: []const u8 = "";
    var y = if (value < 0) -value else value;
    while (y != 0) : (y /= 10) {
        s = [_]u8{@truncate(u8, ((y % 10) + 48))} ++ s;
    }
    if (value < 0) {
        s = [_]u8{'-'} ++ s;
    }
    return s;
}
fn stupid(comptime value: comptime_int) []const u8 {
    if (value < 0) {
        const s: []const u8 = @typeName([-value]void);
        return "-" ++ s[1 .. s.len - 5];
    } else {
        const s: []const u8 = @typeName([value]void);
        return s[1 .. s.len - 5];
    }
}
test {
    @setEvalBranchQuota(~@as(u32, 0));
    comptime var i: u64 = 0;
    inline while (i != 100_000) : (i += 1) {
        _ = comptime stupid(i);
    }
}

pub fn main() !void {
    const k = @as(@Type(.EnumLiteral), undefined);
    _ = k;

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
    const f = struct {
        fn eql(
            comptime text: []const u8,
            comptime v1: u32,
            comptime v2: u32,
            comptime v3: u32,
        ) !void {
            const v = try comptime builtin.Version.parseVersion(text);
            comptime builtin.static.assertEqual(u32, v.major, v1);
            comptime builtin.static.assertEqual(u32, v.minor, v2);
            comptime builtin.static.assertEqual(u32, v.patch, v3);
        }
        fn err(comptime text: []const u8, comptime expected_err: anyerror) !void {
            _ = comptime builtin.Version.parseVersion(text) catch |actual_err| {
                if (actual_err == expected_err) return;
                return actual_err;
            };
            return error.Unreachable;
        }
    };
    try f.eql("2.6.32.11-svn21605", 2, 6, 32); // Debian PPC
    try f.eql("2.11.2(0.329/5/3)", 2, 11, 2); // MinGW
    try f.eql("5.4.0-1018-raspi", 5, 4, 0); // Ubuntu
    try f.eql("5.7.12_3", 5, 7, 12); // Void
    try f.eql("2.13-DEVELOPMENT", 2, 13, 0); // DragonFly
    try f.eql("2.3-35", 2, 3, 0);
    try f.eql("1a.4", 1, 0, 0);
    try f.eql("3.b1.0", 3, 0, 0);
    try f.eql("1.4beta", 1, 4, 0);
    try f.eql("2.7.pre", 2, 7, 0);
    try f.eql("0..3", 0, 0, 0);
    try f.eql("8.008.", 8, 8, 0);
    try f.eql("01...", 1, 0, 0);
    try f.eql("55", 55, 0, 0);
    try f.eql("4294967295.0.1", 4294967295, 0, 1);
    try f.eql("429496729_6", 429496729, 0, 0);
    try f.err("foobar", error.InvalidVersion);
    try f.err("", error.InvalidVersion);
    try f.err("-1", error.InvalidVersion);
    try f.err("+4", error.InvalidVersion);
    try f.err(".", error.InvalidVersion);
    try f.err("....3", error.InvalidVersion);
    try f.err("4294967296", error.Overflow);
    try f.err("5000877755", error.Overflow);

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
