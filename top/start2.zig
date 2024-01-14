var stack: usize = 0;
pub export fn _start() callconv(.Naked) void {
    @setRuntimeSafety(false);
    asm volatile (
        \\ xorl %%ebp, %%ebp
        \\ movq %%rsp, %[stack]
        \\ andq $-16, %%rsp
        \\ callq %[start:P]
        : [stack] "=m" (stack),
        : [start] "X" (&start),
    );
}
pub fn exit(code: u8) noreturn {
    @setRuntimeSafety(false);
    asm volatile (
        \\ syscall
        :
        : [_] "{rax}" (60),
          [_] "{rdi}" (code),
    );
    unreachable;
}
const start = switch (@typeInfo(@TypeOf(main)).Fn.params.len) {
    0 => startSimple,
    1 => startArgs,
    2 => startArgsEnviron,
    3 => startArgsEnvironAuxvec,
    else => @compileError("invalid function parameters for `main`: valid signatures: " ++ valid_mains),
};
const finish = switch (@typeInfo(@TypeOf(main)).Fn.return_type.?) {
    void => finishSimple,
    u8 => exit,
    else => |return_type| blk: {
        if (@typeInfo(return_type) == .ErrorUnion and
            @typeInfo(return_type).ErrorUnion.payload == void)
        {
            break :blk finishSimpleError;
        }
        if (@typeInfo(return_type) == .ErrorUnion and
            @typeInfo(return_type).ErrorUnion.payload == u8)
        {
            break :blk finishCodeError;
        }
        @compileError("invalid function parameters for `main`: valid signatures: " ++ valid_mains);
    },
};
fn startSimple() void {
    finish(main());
}
fn startArgs() noreturn {
    const args_len: usize = @as(*usize, @ptrFromInt(stack)).*;
    const args_addr: usize = stack +% 8;
    const args: [*][*:0]u8 = @ptrFromInt(args_addr);
    finish(main(args[0..args_len]));
}
fn startArgsEnviron() noreturn {
    const args_len: usize = @as(*usize, @ptrFromInt(stack)).*;
    const args_addr: usize = stack +% 8;
    const vars_addr: usize = args_addr +% ((args_len +% 1) *% 8);
    const args: [*][*:0]u8 = @ptrFromInt(args_addr);
    const vars: [*][*:0]u8 = @ptrFromInt(vars_addr);
    const vars_len: usize = blk_1: {
        var len: usize = 0;
        while (@intFromPtr(vars[len]) != 0) len +%= 1;
        break :blk_1 len;
    };
    finish(main(args[0..args_len], vars[0..vars_len]));
}
fn startArgsEnvironAuxvec() noreturn {
    const args_len: usize = @as(*usize, @ptrFromInt(stack)).*;
    const args_addr: usize = stack +% 8;
    const vars_addr: usize = args_addr +% ((args_len +% 1) *% 8);
    const args: [*][*:0]u8 = @ptrFromInt(args_addr);
    const vars: [*][*:0]u8 = @ptrFromInt(vars_addr);
    const vars_len: usize = blk_1: {
        var len: usize = 0;
        while (@intFromPtr(vars[len]) != 0) len +%= 1;
        break :blk_1 len;
    };
    const auxv: *const anyopaque = @ptrFromInt(vars_addr +% 8 +% (vars_len * 8));
    finish(main(args[0..args_len], vars[0..vars_len], auxv));
}
fn finishSimple(_: void) noreturn {
    exit(0);
}
fn finishCode(ret: u8) noreturn {
    exit(ret);
}
fn finishSimpleError(ret: anyerror!void) noreturn {
    if (ret) {
        exit(0);
    } else |_| {}
}
fn finishCodeError(ret: anyerror!u8) noreturn {
    if (ret) |code| {
        exit(code);
    } else |_| {}
}
const main = @import("root").main;
const valid_mains =
    \\pub fn () void;
    \\pub fn () !void;
    \\pub fn () !u8;
    \\pub fn ([][*:0]u8) void;
    \\pub fn ([][*:0]u8) !void;
    \\pub fn ([][*:0]u8) !u8;
    \\pub fn ([][*:0]u8, [][*:0]u8) void;
    \\pub fn ([][*:0]u8, [][*:0]u8) !void;
    \\pub fn ([][*:0]u8, [][*:0]u8) !u8;
    \\pub fn ([][*:0]u8, [][*:0]u8, *const anyopaque) void;
    \\pub fn ([][*:0]u8, [][*:0]u8, *const anyopaque) !void;
    \\pub fn ([][*:0]u8, [][*:0]u8, *const anyopaque) !u8;
;
