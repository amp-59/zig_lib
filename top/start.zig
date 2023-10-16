//! This file is always evaluated by `std.zig` (when zig_lib is acting as the
//! standard library), but not by `zig_lib.zig` (when the library is used as a
//! package). It serves the same purpose in both cases, achieved by different
//! means.

const proc = @import("./proc.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");

pub const panic = debug.panic;
pub usingnamespace debug.panic_extra;
pub usingnamespace ZigLibEntry;
pub var stack: usize = undefined;

pub fn Start(comptime entry: anytype) type {
    return struct {
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
                : [start] "X" (&entry),
            );
        }
    };
}

const ZigLibEntry = Start(start);

const UserEntry = struct {
    const _start = builtin.root._start;
};
comptime {
    if (builtin.output_mode == .Exe) {
        @export(ZigLibEntry._start, .{ .name = "_start", .linkage = .Strong });
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
    proc.initializeRuntime();
    proc.initializeAbsoluteState(vars[0..vars_len]);
    const params = switch (main_type_info.Fn.params.len) {
        0 => .{},
        1 => .{args[0..args_len]},
        2 => .{ args[0..args_len], vars[0..vars_len] },
        3 => .{ args[0..args_len], vars[0..vars_len], auxv },
        else => unreachable,
    };
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
            return proc.exitError(err, @truncate(@intFromError(err)));
        }
    }
    if (main_return_type_info == .ErrorUnion and
        main_return_type_info.ErrorUnion.payload == u8)
    {
        if (@call(.auto, builtin.root.main, params)) |rc| {
            return proc.exitNotice(rc);
        } else |err| {
            return proc.exitError(err, @truncate(@intFromError(err)));
        }
    }
    @compileError(@TypeOf(main_return_type_info, .ErrorSet));
}
