const builtin = @import("./builtin.zig");
const meta = @import("./meta.zig");

pub const is_verbose: bool = true;
pub const is_correct: bool = true;

pub export fn _start() callconv(.Naked) noreturn {
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

pub fn main() !void {
    builtin.assertEqual(u64, 8, meta.alignAW(7));
    builtin.assertEqual(u64, 16, meta.alignAW(9));
    builtin.assertEqual(u64, 32, meta.alignAW(25));
    builtin.assertEqual(u64, 64, meta.alignAW(48));
}
