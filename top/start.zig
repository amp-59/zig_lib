//! This file is always evaluated by `std.zig` (when zig_lib is acting as the
//! standard library), but not by `zig_lib.zig` (when the library is used as a
//! package). It serves the same purpose in both cases, achieved by different
//! means.
const proc = @import("./proc.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");

pub const panic = debug.panic;
pub usingnamespace debug.panic_extra;

pub var stack: usize = undefined;

pub fn _start() callconv(.Naked) void {
    asm volatile (switch (builtin.cpu.arch) {
            .x86_64 =>
            \\ xorl %%ebp, %%ebp
            \\ movq %%rsp, %[stack]
            \\ andq $-16, %%rsp
            \\ callq %[start:P]
            ,
            .aarch64, .aarch64_be =>
            \\ mov fp, #0
            \\ mov lr, #0
            \\ mov x0, sp
            \\ str x0, %[stack]
            \\ b %[start]
            ,
            else => @compileError("unsupported arch"),
        }
        : [stack] "=m" (stack),
        : [start] "X" (&start),
    );
}
comptime {
    if (builtin.output_mode == .Exe) {
        @export(_start, .{ .name = "_start", .linkage = .Strong });
    }
}
pub fn start() callconv(.C) noreturn {
    @setRuntimeSafety(false);
    @setAlignStack(16);
    if (builtin.output_mode != .Exe) {
        unreachable;
    }
    const main_type_info: builtin.Type = @typeInfo(@TypeOf(builtin.root.main));
    const main_return_type: type = main_type_info.Fn.return_type.?;
    const main_return_type_info: builtin.Type = @typeInfo(main_return_type);
    const params = blk_0: {
        if (main_type_info.Fn.params.len == 0) {
            break :blk_0 .{};
        }
        if (main_type_info.Fn.params.len == 1) {
            const args_len: u64 = @as(*u64, @ptrFromInt(stack)).*;
            const args_addr: u64 = stack +% 8;
            const args: [*][*:0]u8 = @ptrFromInt(args_addr);
            break :blk_0 .{args[0..args_len]};
        }
        if (main_type_info.Fn.params.len == 2) {
            const args_len: u64 = @as(*u64, @ptrFromInt(stack)).*;
            const args_addr: u64 = stack +% 8;
            const vars_addr: u64 = stack +% 16 +% (args_len * 8);
            const args: [*][*:0]u8 = @ptrFromInt(args_addr);
            const vars: [*][*:0]u8 = @ptrFromInt(vars_addr);
            const vars_len: u64 = blk_1: {
                var len: u64 = 0;
                while (@intFromPtr(vars[len]) != 0) len += 1;
                break :blk_1 len;
            };
            break :blk_0 .{ args[0..args_len], vars[0..vars_len] };
        }
        if (main_type_info.Fn.params.len == 3) {
            const auxv_type: type = main_type_info.Fn.params[2].type orelse *const anyopaque;
            const args_len: u64 = @as(*u64, @ptrFromInt(stack)).*;
            const args_addr: u64 = stack +% 8;
            const vars_addr: u64 = args_addr +% 8 +% (args_len * 8);
            const args: [*][*:0]u8 = @ptrFromInt(args_addr);
            const vars: [*][*:0]u8 = @ptrFromInt(vars_addr);
            const vars_len: u64 = blk_1: {
                var len: u64 = 0;
                while (@intFromPtr(vars[len]) != 0) len += 1;
                break :blk_1 len;
            };
            const auxv_addr: u64 = vars_addr +% 8 +% (vars_len * 8);
            const auxv: auxv_type = @ptrFromInt(auxv_addr);
            break :blk_0 .{ args[0..args_len], vars[0..vars_len], auxv };
        }
    };
    proc.initializeRuntime();
    if (main_return_type == void) {
        @call(.auto, builtin.root.main, params);
        return proc.exitNotice(0);
    }
    if (main_return_type == u8) {
        return proc.exitNotice(@call(.auto, builtin.root.main, params));
    }
    if (main_return_type_info == .ErrorUnion and
        main_return_type_info.ErrorUnion.payload == void)
    {
        if (@call(.auto, builtin.root.main, params)) {
            return proc.exitNotice(0);
        } else |err| {
            debug.alarm(@errorName(err), @errorReturnTrace(), @returnAddress());
            return proc.exit(@intCast(@intFromError(err)));
        }
    }
    if (main_return_type_info == .ErrorUnion and
        main_return_type_info.ErrorUnion.payload == u8)
    {
        if (@call(.auto, builtin.root.main, params)) |rc| {
            return proc.exitNotice(rc);
        } else |err| {
            debug.alarm(@errorName(err), @errorReturnTrace(), @returnAddress());
            return proc.exit(@intCast(@intFromError(err)));
        }
    }
    @compileError(@TypeOf(main_return_type_info, .ErrorSet));
}
