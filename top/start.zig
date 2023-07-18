const builtin = @import("./builtin.zig");
const proc = @import("./proc.zig");
comptime {
    _ = @import("./mach.zig");
}
pub usingnamespace blk: {
    if (@hasDecl(builtin.root, "zig_lib") and builtin.root.zig_lib) {
        // zl is captain now.
        if (!@hasDecl(builtin.root, "_start")) {
            // User has not defined `_start` in `root`.
            @export(_0._start, .{ .name = "_start" });
        }
        break :blk _0;
    } else if (builtin.output_mode == .Exe) {
        break :blk _1;
    }
    break :blk builtin.debug;
};
const _0 = struct {
    fn _start() callconv(.Naked) noreturn {
        proc.static.stack_addr = asm volatile (
            \\xorq  %%rbp,  %%rbp
            : [argc] "={rsp}" (-> u64),
        );
        @call(.never_inline, proc.start, .{});
    }
};
const _1 = struct {
    pub export fn _start() callconv(.Naked) noreturn {
        proc.static.stack_addr = asm volatile (
            \\xorq  %%rbp,  %%rbp
            : [argc] "={rsp}" (-> u64),
        );
        @call(.never_inline, proc.start, .{});
    }
    pub usingnamespace builtin.debug;
};
