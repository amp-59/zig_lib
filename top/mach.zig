// Unused, but potentially useful for testing.
pub const generic = struct {
    pub inline fn sub(arg1: anytype, arg2: @TypeOf(arg1)) @TypeOf(arg1 -% arg2) {
        return arg1 -% arg2;
    }
    pub inline fn add(arg1: anytype, arg2: @TypeOf(arg1)) @TypeOf(arg1 +% arg2) {
        return arg1 +% arg2;
    }
    pub inline fn mul(arg1: anytype, arg2: @TypeOf(arg1)) @TypeOf(arg1 *% arg2) {
        return arg1 *% arg2;
    }
    pub inline fn div(arg1: anytype, arg2: @TypeOf(arg1)) @TypeOf(arg1 / arg2) {
        return arg1 / arg2;
    }
};

const is_small = @import("builtin").mode == .ReleaseSmall;
const is_fast = @import("builtin").mode == .ReleaseFast;
const is_debug = @import("builtin").mode == .Debug;
const is_test = @import("builtin").is_test;

pub inline fn testEqualMany8(l_values: []const u8, r_values: []const u8) bool {
    if (@inComptime()) {
        if (l_values.len != r_values.len) {
            return false;
        }
        if (l_values.ptr == r_values.ptr) {
            return true;
        }
        for (l_values, r_values) |l, r| {
            if (l != r) {
                return false;
            }
        }
        return true;
    } else {
        return _0.asmTestEqualMany8(l_values.ptr, l_values.len, r_values.ptr, r_values.len);
    }
}
pub inline fn memcpyMulti(noalias dest: [*]u8, src: []const []const u8) u64 {
    if (@inComptime()) {
        var len: u64 = 0;
        for (src) |bytes| {
            for (bytes) |byte| {
                dest[len] = byte;
                len +%= 1;
            }
        }
        return len;
    } else {
        return _1.asmMemcpyMulti(dest, src.ptr, src.len);
    }
}
pub fn manyToSlice80(str: [*]u8) [:0]u8 {
    @setRuntimeSafety(false);
    return str[0.._3.strlen(str) :0];
}
pub fn assert(cond: bool, msg: []const u8) void {
    _2.asmAssert(cond, msg.ptr, msg.len);
}
const _0 = struct {
    extern fn asmTestEqualMany8(arg1: [*]const u8, arg1_len: u64, arg2: [*]const u8, arg2_len: u64) callconv(.C) bool;
    comptime {
        asm (
            \\.intel_syntax noprefix
            \\asmTestEqualMany8:
            \\  cmp     rsi, rcx
            \\  jne     2f
            \\  mov     al, 1f
            \\  cmp     rdi, rdx
            \\  je      1f
            \\  test    rsi, rsi
            \\  je      1f
            \\  dec     rsi
            \\  xor     ecx, ecx
            \\0:
            \\  movzx   eax, byte ptr [rdi + rcx]
            \\  cmp     al,  byte ptr [rdx + rcx]
            \\  sete    al
            \\  jne     1f
            \\  lea     r8,  [rcx + 1]
            \\  cmp     rsi, rcx
            \\  mov     rcx, r8
            \\  jne     0b
            \\1:
            \\  ret
            \\2:
            \\  xor    eax,  eax
            \\  ret
        );
    }
};
const _1 = struct {
    extern fn asmMemcpyMulti(noalias dest: [*]u8, src: [*]const []const u8, len: u64) callconv(.C) u64;
    comptime {
        asm (
            \\.intel_syntax noprefix
            \\asmMemcpyMulti:
            \\  xor     r8d, r8d
            \\  xor     ecx, ecx
            \\  cmp     r8, rdx
            \\  jne     9f
            \\  mov     rax, rcx
            \\  ret
            \\9:
            \\  push    rbx
            \\5:
            \\  mov     r10, qword ptr [rsi]
            \\  mov     r9, qword ptr [rsi + 8]
            \\  xor     eax, eax
            \\  lea     r11, [rdi + rcx]
            \\3:
            \\  cmp     rax, r9
            \\  je      11f
            \\  mov     bl, byte ptr [r10 + rax]
            \\  mov     byte ptr [r11 + rax], bl
            \\  inc     rax
            \\  jmp     3b
            \\11:
            \\  inc     r8
            \\  add     rcx, rax
            \\  add     rsi, 16
            \\  cmp     r8, rdx
            \\  jne     5b
            \\  mov     rax, rcx
            \\  pop     rbx
            \\  ret
        );
    }
};
const _2 = struct {
    extern fn asmAssert(b: bool, buf_ptr: [*]const u8, buf_len: u64) callconv(.C) void;
    comptime {
        asm (
            \\.intel_syntax noprefix
            \\asmAssert:
            \\  test    edi, edi
            \\  jne     0f
            \\  mov     eax, 1
            \\  mov     edi, 2
            \\  syscall # write
            \\  mov     eax, 60
            \\  mov     edi, 2
            \\  syscall # exit
            \\0:
            \\  ret
        );
    }
};
const _3 = struct {
    extern fn strlen(str: [*]u8) callconv(.C) u64;
    comptime {
        asm (
            \\  .intel_syntax noprefix
            \\strlen:
            \\  mov     rax, -1
            \\0:
            \\  cmp     byte ptr [rdi + rax + 1], 0
            \\  lea     rax, [rax + 1]
            \\  jne     0b
            \\  ret
            \\
        );
    }
};
