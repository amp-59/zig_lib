pub export fn memset(dest: [*]u8, value: u8, count: usize) callconv(.C) void {
    if (@import("builtin").mode == .ReleaseSmall) {
        asm volatile ("rep stosb"
            :
            : [_] "{rdi}" (dest),
              [_] "{al}" (value),
              [_] "{rcx}" (count),
            : "rax", "rdi", "rcx", "memory"
        );
    } else {
        @setRuntimeSafety(false);
        var index: usize = 0;
        while (index != count) : (index += 1) {
            dest[index] = value;
        }
    }
}
