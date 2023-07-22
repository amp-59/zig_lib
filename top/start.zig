//! This file is always evaluated by `std.zig` (when zig_lib is acting as the
//! standard library), but not by `zig_lib.zig` (when the library is used as a
//! package). It serves the same purpose in both cases, achieved by different
//! means.
const proc = @import("./proc.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");

comptime {
    if (builtin.is_zig_lib) {
        if (@hasDecl(builtin.root, "_start")) {
            @export(builtin.root._start, .{ .name = "_start" });
        } else {
            @export(_0._start, .{ .name = "_start" });
        }
    } else {
        //
    }
    if (builtin.output_mode != .Exe) {
        _ = @import("./mach.zig");
    }
}

pub usingnamespace blk: {
    if (builtin.is_zig_lib) {
        break :blk _0;
    } else if (builtin.output_mode == .Exe) {
        if (!@hasDecl(builtin.root, "_start")) {
            break :blk _1;
        }
    }
    break :blk debug;
};

const _0 = struct {
    fn _start() callconv(.Naked) if (builtin.output_mode == .Exe) noreturn else void {
        proc.static.stack_addr = asm volatile (
            \\xorq  %%rbp,  %%rbp
            : [argc] "={rsp}" (-> u64),
        );
        @call(.never_inline, proc.start, .{});
    }
};
const _1 = struct {
    pub export fn _start() callconv(.Naked) if (builtin.output_mode == .Exe) noreturn else void {
        proc.static.stack_addr = asm volatile (
            \\xorq  %%rbp,  %%rbp
            : [argc] "={rsp}" (-> u64),
        );
        @call(.never_inline, proc.start, .{});
    }
    pub usingnamespace debug;
};
