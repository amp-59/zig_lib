const zl = @import("../../zig_lib.zig");

pub usingnamespace zl.start;
pub const panic_return_value: u8 = 0;

export fn causeSentinelMismatch() void {
    var a: [4096]u8 = undefined;
    const b: [:0]u8 = a[0..512 :0];
    b[256] = 'b';
}

export fn causePanic() void {
    var a: [512]u8 = undefined;
    var x: u64 = 0x10000;
    var y: u64 = 0x10010;
    zl.debug.assertEqual(u64, x, y);
    var u: union(enum(u8)) {
        a: u64,
        b: u32,
    } = .{ .a = 25 };
    u.a = u.b;
    var idx: usize = 512;
    a[idx] = 'a';
    var b: [:0]u8 = a[0..512 :0];
    b[256] = 'b';
    a[0] = 'a';
    b = a[@intFromPtr(&a)..512 :0];
    b[256] = 'b';
    causePanic();
    unreachable;
}
pub fn main() void {
    causePanic();
}
