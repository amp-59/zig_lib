//! This file is always evaluated by `std.zig` (when zig_lib is acting as the
//! standard library), but not by `zig_lib.zig` (when the library is used as a
//! package). It serves the same purpose in both cases, achieved by different
//! means.
const proc = @import("proc.zig");
const debug = @import("debug.zig");
const builtin = @import("builtin.zig");
pub const panic = debug.panic;
pub const panicNew = debug.safety.panicNew;
pub usingnamespace debug.panic_extra;
pub var stack: usize = 0;
pub fn Start(comptime entry: anytype) type {
    return struct {
        pub fn _start() callconv(.Naked) void {
            asm volatile (
                \\ xorl %%ebp, %%ebp
                \\ movq %%rsp, %[stack]
                \\ andq $-16, %%rsp
                \\ callq %[start:P]
                : [stack] "=m" (stack),
                : [start] "X" (&entry),
            );
        }
    };
}
comptime {
    if (builtin.output_mode == .Exe and
        (@hasDecl(builtin.root, "Start") or
        (@hasDecl(builtin.root, "want_zig_lib_start") and builtin.root.want_zig_lib_start)))
    {
        @export(_start, .{ .name = "_start", .linkage = .Strong });
    }
}
pub const _start = Start(start)._start;
pub fn start() callconv(.C) noreturn {
    @setRuntimeSafety(false);
    @setAlignStack(16);
    if (builtin.output_mode != .Exe) {
        @compileError("uncallable");
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
        else => @compileError("invalid number of arguments"),
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
            if (@errorReturnTrace()) |st| {
                debug.alarm(@errorName(err), st, null);
            }
            return proc.exitError(err, @truncate(@intFromError(err)));
        }
    }
    if (main_return_type_info == .ErrorUnion and
        main_return_type_info.ErrorUnion.payload == u8)
    {
        if (@call(.auto, builtin.root.main, params)) |rc| {
            return proc.exitNotice(rc);
        } else |err| {
            if (@errorReturnTrace()) |st| {
                debug.alarm(@errorName(err), st, null);
            }
            return proc.exitError(err, @truncate(@intFromError(err)));
        }
    }
    @compileError(@TypeOf(main_return_type_info, .ErrorSet));
}
