    .section .text.
    .intel_syntax noprefix

    .globl  asmMaxWidths
    .type   asmMaxWidths,@function
asmMaxWidths:
    push    r15
    push    r14
    push    rbx
    mov     rcx, qword ptr [rdi + 72]
    mov     r8, qword ptr [rdi + 80]
    mov     r9, qword ptr [rdi + 88]
    xor     edx, edx
    xor     eax, eax
1:
    cmp     r9, r8
    je      2f
    mov     r10, qword ptr [rcx + 8]
    test    r10, r10
    je      3f
    mov     rsi, qword ptr [rcx]
    mov     r15, rdx
    mov     rdi, rax
    mov     rcx, qword ptr [rsi + 24]
    mov     r11, qword ptr [rsi + 32]
    mov     r14, qword ptr [rsi + 40]
6:
    cmp     r14, r11
    je      7f
    mov     rbx, qword ptr [rcx + 8]
    test    rbx, rbx
    je      9f
    mov     rcx, qword ptr [rcx]
    mov     rsi, qword ptr [rcx + 8]
    mov     rcx, qword ptr [rcx + 24]
    cmp     rdi, rsi
    cmovbe  rdi, rsi
    cmp     r15, rcx
    cmovbe  r15, rcx
    mov     rcx, rbx
    jmp     6b
7:
    mov     rcx, r10
    jmp     1b
9:
    mov     rcx, r10
    mov     rdx, r15
    mov     rax, rdi
    jmp     1b
2:
    xor     edx, edx
    xor     eax, eax
3:
    add     rax, 8
    add     rdx, 8
    and     rax, -8
    and     rdx, -8
    pop     rbx
    pop     r14
    pop     r15
    ret

    .globl  asmWriteAllCommands
    .type   asmWriteAllCommands,@function
asmWriteAllCommands:
    push    rbp
    push    r15
    push    r14
    push    r13
    push    r12
    push    rbx
    sub     rsp, 88
    mov     rax, qword ptr [rdi + 80]
    mov     rcx, qword ptr [rdi + 88]
    mov     rbp, qword ptr [rdi + 72]
    mov     r14, rdx
    mov     r13, rsi
    xor     r15d, r15d
    mov     qword ptr [rsp + 24], rax
    mov     qword ptr [rsp + 16], rcx
1:
    mov     rax, qword ptr [rsp + 16]
    cmp     rax, qword ptr [rsp + 24]
    je      2f
    mov     rax, qword ptr [rbp + 8]
    test    rax, rax
    je      3f
    mov     rcx, qword ptr [rbp]
    mov     qword ptr [rsp + 8], rax
    lea     rax, [rip + c_lf]
    lea     rdi, [r13 + r15]
    lea     rsi, [rsp + 56]
    vmovups xmm0, xmmword ptr [rcx]
    vmovups xmmword ptr [rsp + 56], xmm0
    mov     qword ptr [rsp + 72], rax
    mov     qword ptr [rsp + 80], 2
    push    2
    pop     rdx
    call    asmMemcpyMulti@PLT
    mov     rdx, qword ptr [rbp]
    add     r15, rax
    mov     qword ptr [rsp + 32], r15
    mov     r12, qword ptr [rdx + 24]
    mov     rcx, qword ptr [rdx + 32]
    mov     rax, qword ptr [rdx + 40]
    mov     qword ptr [rsp + 48], rcx
    mov     qword ptr [rsp + 40], rax
6:
    mov     rax, qword ptr [rsp + 40]
    cmp     rax, qword ptr [rsp + 48]
    je      7f
    mov     rbp, qword ptr [r12 + 8]
    test    rbp, rbp
    je      9f
    lea     rdi, [r13 + r15]
    push    32
    pop     rbx
    mov     esi, ebx
    push    4
    pop     rdx
    call    memset@PLT
    mov     rax, qword ptr [r12]
    lea     rdi, [r13 + r15 + 4]
    mov     rsi, qword ptr [rax]
    mov     rdx, qword ptr [rax + 8]
    call    memcpy@PLT
    mov     rax, qword ptr [r12]
    mov     rdx, r14
    mov     esi, ebx
    mov     rax, qword ptr [rax + 8]
    lea     rdi, [rax + r15 + 4]
    sub     rdx, rax
    add     rdi, r13
    call    memset@PLT
    mov     rax, qword ptr [r12]
    lea     rbx, [r15 + r14 + 4]
    lea     rdi, [r13 + rbx]
    mov     rsi, qword ptr [rax + 16]
    mov     rdx, qword ptr [rax + 24]
    call    memcpy@PLT
    mov     rax, qword ptr [r12]
    mov     r12, rbp
    mov     rax, qword ptr [rax + 24]
    lea     rcx, [rax + rbx]
    lea     r15, [rax + rbx + 1]
    mov     byte ptr [r13 + rcx], 10
    jmp     6b
7:
    mov     rbp, qword ptr [rsp + 8]
    mov     r15, qword ptr [rsp + 32]
    jmp     1b
9:
    mov     rbp, qword ptr [rsp + 8]
    jmp     1b
2:
    xor     r15d, r15d
3:
    mov     rax, r15
    add     rsp, 88
    pop     rbx
    pop     r12
    pop     r13
    pop     r14
    pop     r15
    pop     rbp
    ret

asmRewind:
  cmp     qword ptr [rdi + 80], 0
  je      4f
  mov     rax, qword ptr [rdi + 64]
  mov     rcx, qword ptr [rax + 8]
  test    rcx, rcx
  je      4f
2:
  mov     rax, qword ptr [rax]
  mov     rdx, qword ptr [rax + 16]
  mov     qword ptr [rax + 24], rdx
  mov     qword ptr [rax + 40], 0
  mov     rax, rcx
  mov     rcx, qword ptr [rcx + 8]
  test    rcx, rcx
  jne     2b
4:
  ret

asmWriteEnv:
    sub     rsp, 64
    vmovups xmm0, xmmword ptr [rsi]
    vmovups xmm1, xmmword ptr [rsi + 16]
    vmovups xmm2, xmmword ptr [rsi + 32]
    vmovups xmm3, xmmword ptr [rsi + 48]
    lea     rax, [rip + zig_exe]
    movabs  rcx, 3
    lea     rdx, [rip + build_root]
    lea     r8, [rip + cache_dir]
    lea     rsi, [rip + global_cache_dir]
    movabs  r9, 8
    mov     qword ptr [rsp - 128], rax
    lea     rax, [rip + dq_sc_lf]
    mov     qword ptr [rsp - 120], 35
    vmovups xmmword ptr [rsp - 112], xmm0
    mov     qword ptr [rsp - 96], rax
    mov     qword ptr [rsp - 88], rcx
    mov     qword ptr [rsp - 80], rdx
    mov     qword ptr [rsp - 72], 38
    vmovups xmmword ptr [rsp - 64], xmm1
    mov     qword ptr [rsp - 48], rax
    mov     qword ptr [rsp - 40], rcx
    mov     qword ptr [rsp - 32], r8
    movabs  r8, 1
    mov     qword ptr [rsp - 24], 37
    vmovups xmmword ptr [rsp - 16], xmm2
    mov     qword ptr [rsp], rax
    mov     qword ptr [rsp + 8], rcx
    mov     qword ptr [rsp + 16], rsi
    mov     qword ptr [rsp + 24], 44
    vmovups xmmword ptr [rsp + 32], xmm3
    mov     qword ptr [rsp + 48], rax
    mov     qword ptr [rsp + 56], rcx
1:
    cmp     r9, 200
    je      3f
    mov     rsi, qword ptr [rsp + r9 - 136]
    mov     rdx, qword ptr [rsp + r9 - 128]
    mov     rax, r8
    syscall # write
    add     r9, 16
    jmp     1b
3:
    add     rsp, 64
    ret

zig_exe:
    .asciz  "pub const zig_exe: [:0]const u8 = \""
    .size   zig_exe, 36
build_root:
    .asciz  "pub const build_root: [:0]const u8 = \""
    .size   build_root, 39
cache_dir:
    .asciz  "pub const cache_dir: [:0]const u8 = \""
    .size   cache_dir, 38
global_cache_dir:
    .asciz  "pub const global_cache_dir: [:0]const u8 = \""
    .size   global_cache_dir, 45
dq_sc_lf:
    .asciz  "\";\n"
    .size   dq_sc_lf, 4
c_lf:
    .asciz  ":\n"
    .size   c_lf, 3
