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
    // try testVersionParser();
    try testRuntimeAssertionsCompile();
    try testStaticAssertionsCompile();
    try testMinMax();
    debug.sampleAllReports();
}
