const builtin = @import("./builtin.zig");

pub const is_verbose: bool = true;
pub const is_correct: bool = true;

fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\xor %%rbp, %%rbp
    );
    callMain() catch |thrown| {
        @panic(@errorName(thrown));
    };
    asm volatile (
        \\movq $60, %%rax
        \\movq $0,  %%rdi
        \\syscall
    );
    unreachable;
}
pub fn callMain() !void {
    @setAlignStack(16);
    return @call(.{ .modifier = .always_inline }, main, .{});
}
pub fn panic(str: []const u8, _: @TypeOf(@errorReturnTrace()), _: ?u64) noreturn {
    asm volatile (
        \\syscall
        \\movq $60, %%rax
        \\movq $2,  %%rdi
        \\syscall
        :
        : [sysno] "{rax}" (1),
          [arg1] "{rdi}" (2),
          [arg2] "{rsi}" (@ptrToInt(str.ptr)),
          [arg3] "{rdx}" (str.len),
    );
    unreachable;
}
fn printArrayOfChars(s: []const u8) struct { buf: [4096]u8, len: u64 } {
    var buf: [4096]u8 = undefined;
    var len: u64 = 0;
    for ("{ ") |c, i| buf[len + i] = c;
    len += 2;
    for (s) |c, i| {
        if (c == 0) {
            for ("0x0") |b, j| buf[len + j] = b;
            len += 3;
        } else {
            for ([_]u8{ '\'', c, '\'' }) |b, j| buf[len + j] = b;
            len += 3;
        }
        if (i != s.len - 1) {
            for (", ") |b, j| buf[len + j] = b;
            len += 2;
        }
    }
    for (" }\n") |c, i| buf[len + i] = c;
    len += 3;
    return .{ .buf = buf, .len = len };
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
    _ = builtin.lib_build_root;
    uint = 0;
    while (uint != 0x10000) : (uint += 1) {
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
    }
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
    arg2 = builtin.addWithOverflow(T, arg1, arg2).value;
    b = builtin.addEquWithOverflow(T, &arg1, arg2);
    arg2 = builtin.sub(T, arg1, arg2);
    arg2 = builtin.subSat(T, arg1, arg2);
    arg2 = builtin.subWrap(T, arg1, arg2);
    builtin.subEqu(T, &arg1, arg2);
    builtin.subEquSat(T, &arg1, arg2);
    builtin.subEquWrap(T, &arg1, arg2);
    arg2 = builtin.subWithOverflow(T, arg1, arg2).value;
    b = builtin.subEquWithOverflow(T, &arg1, arg2);
    arg1 = builtin.mul(T, arg1, arg2);
    arg1 = builtin.mulSat(T, arg1, arg2);
    arg1 = builtin.mulWrap(T, arg1, arg2);
    builtin.mulEqu(T, &arg1, arg2);
    builtin.mulEquSat(T, &arg1, arg2);
    builtin.mulEquWrap(T, &arg1, arg2);
    arg1 = builtin.mulWithOverflow(T, arg1, arg2).value;
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
    arg1 = builtin.shlWithOverflow(T, arg1, arg2).value;
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
