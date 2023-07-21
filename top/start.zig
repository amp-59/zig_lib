const proc = @import("./proc.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
comptime {
    _ = @import("./mach.zig");
}
pub usingnamespace blk: {
    if (builtin.is_zig_lib) {
        // zl is captain now.
        if (!@hasDecl(builtin.root, "_start")) {
            // User has not defined `_start` in `root`.
            @export(_0._start, .{ .name = "_start" });
        }
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
