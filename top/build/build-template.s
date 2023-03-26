        .intel_syntax noprefix
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

asmWriteAllCommands:
    push    rbp
    push    r15
    push    r14
    push    r13
    push    r12
    push    rbx
    mov     rax, qword ptr [rdi + 88]
    cmp     rax, qword ptr [rdi + 80]
    je      .asmWriteAllCommands58
    mov     r9, qword ptr [rdi + 72]
    mov     rcx, qword ptr [r9 + 8]
    test    rcx, rcx
    je      .asmWriteAllCommands58
    lea     rdi, [rsi + 96]
    lea     rbp, [rsi + rdx + 4]
    lea     rax, [rsi + 4]
    lea     r10, [rsi + 100]
    xor     r8d, r8d
    mov     qword ptr [rsp - 32], rdi
    lea     rdi, [rsi + rdx + 100]
    mov     qword ptr [rsp - 40], rax
    mov     qword ptr [rsp - 16], r10
    mov     qword ptr [rsp - 48], rbp
    mov     qword ptr [rsp - 24], rdi
    jmp     .asmWriteAllCommands4
    .p2align    4, 0x90
.asmWriteAllCommands3:
    mov     r9, qword ptr [rsp - 8]
    mov     rcx, qword ptr [r9 + 8]
    test    rcx, rcx
    je      .asmWriteAllCommands59
.asmWriteAllCommands4:
    mov     rax, qword ptr [r9]
    mov     qword ptr [rsp - 8], rcx
    lea     rcx, [rsi + r8]
    mov     r10, qword ptr [rax + 8]
    test    r10, r10
    je      .asmWriteAllCommands18
    mov     rbx, qword ptr [rax]
    cmp     r10, 16
    jb      .asmWriteAllCommands7
    mov     rax, rcx
    sub     rax, rbx
    cmp     rax, 128
    jae     .asmWriteAllCommands8
.asmWriteAllCommands7:
    xor     edi, edi
    jmp     .asmWriteAllCommands16
.asmWriteAllCommands8:
    cmp     r10, 128
    jae     .asmWriteAllCommands10
    xor     edi, edi
    jmp     .asmWriteAllCommands14
.asmWriteAllCommands10:
    mov     rax, qword ptr [rsp - 32]
    mov     rdi, r10
    xor     ebp, ebp
    and     rdi, -128
    add     rax, r8
    .p2align    4, 0x90
.asmWriteAllCommands11:
    vmovups ymm0, ymmword ptr [rbx + rbp]
    vmovups ymm1, ymmword ptr [rbx + rbp + 32]
    vmovups ymm2, ymmword ptr [rbx + rbp + 64]
    vmovups ymm3, ymmword ptr [rbx + rbp + 96]
    vmovups ymmword ptr [rax + rbp - 96], ymm0
    vmovups ymmword ptr [rax + rbp - 64], ymm1
    vmovups ymmword ptr [rax + rbp - 32], ymm2
    vmovups ymmword ptr [rax + rbp], ymm3
    sub     rbp, -128
    cmp     rdi, rbp
    jne     .asmWriteAllCommands11
    mov     rbp, qword ptr [rsp - 48]
    cmp     r10, rdi
    je      .asmWriteAllCommands18
    test    r10b, 112
    je      .asmWriteAllCommands16
.asmWriteAllCommands14:
    mov     rax, rdi
    mov     rdi, r10
    and     rdi, -16
    .p2align    4, 0x90
.asmWriteAllCommands15:
    vmovups xmm0, xmmword ptr [rbx + rax]
    vmovups xmmword ptr [rcx + rax], xmm0
    add     rax, 16
    cmp     rdi, rax
    jne     .asmWriteAllCommands15
    jmp     .asmWriteAllCommands17
    .p2align    4, 0x90
.asmWriteAllCommands16:
    movzx   eax, byte ptr [rbx + rdi]
    mov     byte ptr [rcx + rdi], al
    inc     rdi
.asmWriteAllCommands17:
    cmp     r10, rdi
    jne     .asmWriteAllCommands16
.asmWriteAllCommands18:
    mov     word ptr [rcx + r10], 2618
    lea     r8, [r8 + r10 + 2]
    mov     rax, qword ptr [r9]
    mov     r13, qword ptr [rax + 32]
    mov     r9, qword ptr [rax + 40]
    cmp     r9, r13
    je      .asmWriteAllCommands3
    mov     r14, qword ptr [rax + 24]
    jmp     .asmWriteAllCommands22
    .p2align    4, 0x90
.asmWriteAllCommands20:
    xor     eax, eax
.asmWriteAllCommands21:
    lea     rcx, [rax + r15]
    lea     r8, [rax + r15 + 1]
    mov     r14, r10
    mov     byte ptr [rsi + rcx], 10
    cmp     r9, r13
    je      .asmWriteAllCommands3
.asmWriteAllCommands22:
    mov     r10, qword ptr [r14 + 8]
    test    r10, r10
    je      .asmWriteAllCommands3
    mov     dword ptr [rsi + r8], 538976288
    lea     r15, [r8 + 4]
    mov     rcx, qword ptr [r14]
    mov     r11, qword ptr [rcx + 8]
    test    r11, r11
    je      .asmWriteAllCommands26
    mov     rcx, qword ptr [rcx]
    cmp     r11, 16
    jb      .asmWriteAllCommands25
    mov     rax, qword ptr [rsp - 40]
    lea     r12, [rax + r8]
    mov     rdi, r12
    sub     rdi, rcx
    cmp     rdi, 128
    jae     .asmWriteAllCommands29
.asmWriteAllCommands25:
    xor     edi, edi
.asmWriteAllCommands38:
    mov     rax, qword ptr [rsp - 40]
    lea     rbx, [rax + r8]
    .p2align    4, 0x90
.asmWriteAllCommands39:
    movzx   eax, byte ptr [rcx + rdi]
    mov     byte ptr [rbx + rdi], al
    inc     rdi
    cmp     r11, rdi
    jne     .asmWriteAllCommands39
.asmWriteAllCommands40:
    mov     rax, qword ptr [r14]
    mov     rdi, qword ptr [rax + 8]
    jmp     .asmWriteAllCommands41
    .p2align    4, 0x90
.asmWriteAllCommands26:
    xor    edi, edi
.asmWriteAllCommands41:
    mov    rcx, rdx
    mov    al, 32
    sub    rcx, rdi
    add    rdi, r15
    add    r15, rdx
    add    rdi, rsi
    rep     stosb    byte ptr es:[rdi], al
    mov     rcx, qword ptr [r14]
    mov     rax, qword ptr [rcx + 24]
    test    rax, rax
    je      .asmWriteAllCommands20
    mov     rcx, qword ptr [rcx + 16]
    cmp     rax, 16
    jb      .asmWriteAllCommands43
    lea     r12, [rbp + r8]
    mov     rdi, r12
    sub     rdi, rcx
    cmp     rdi, 128
    jae     .asmWriteAllCommands46
.asmWriteAllCommands43:
    xor     edi, edi
.asmWriteAllCommands55:
    add     r8, rbp
    .p2align    4, 0x90
.asmWriteAllCommands56:
    movzx   ebx, byte ptr [rcx + rdi]
    mov     byte ptr [r8 + rdi], bl
    inc     rdi
    cmp     rax, rdi
    jne     .asmWriteAllCommands56
.asmWriteAllCommands57:
    mov     rax, qword ptr [r14]
    mov     rax, qword ptr [rax + 24]
    jmp     .asmWriteAllCommands21
.asmWriteAllCommands29:
    cmp     r11, 128
    jae     .asmWriteAllCommands31
    xor     edi, edi
    jmp     .asmWriteAllCommands35
.asmWriteAllCommands46:
    cmp     rax, 128
    jae     .asmWriteAllCommands48
    xor     edi, edi
    jmp     .asmWriteAllCommands52
.asmWriteAllCommands31:
    mov     rax, qword ptr [rsp - 16]
    mov     rdi, r11
    xor     ebp, ebp
    and     rdi, -128
    lea     rbx, [rax + r8]
    .p2align    4, 0x90
.asmWriteAllCommands32:
    vmovups ymm0, ymmword ptr [rcx + rbp]
    vmovups ymm1, ymmword ptr [rcx + rbp + 32]
    vmovups ymm2, ymmword ptr [rcx + rbp + 64]
    vmovups ymm3, ymmword ptr [rcx + rbp + 96]
    vmovups ymmword ptr [rbx + rbp - 96], ymm0
    vmovups ymmword ptr [rbx + rbp - 64], ymm1
    vmovups ymmword ptr [rbx + rbp - 32], ymm2
    vmovups ymmword ptr [rbx + rbp], ymm3
    sub     rbp, -128
    cmp     rdi, rbp
    jne     .asmWriteAllCommands32
    mov     rbp, qword ptr [rsp - 48]
    cmp     r11, rdi
    je      .asmWriteAllCommands40
    test    r11b, 112
    je      .asmWriteAllCommands38
.asmWriteAllCommands35:
    mov     rbx, rdi
    mov     rdi, r11
    and     rdi, -16
    .p2align    4, 0x90
.asmWriteAllCommands36:
    vmovups xmm0, xmmword ptr [rcx + rbx]
    vmovups xmmword ptr [r12 + rbx], xmm0
    add     rbx, 16
    cmp     rdi, rbx
    jne     .asmWriteAllCommands36
    cmp     r11, rdi
    je      .asmWriteAllCommands40
    jmp     .asmWriteAllCommands38
.asmWriteAllCommands48:
    mov     rbp, qword ptr [rsp - 24]
    mov     rdi, rax
    xor     ebx, ebx
    and     rdi, -128
    add     rbp, r8
    .p2align    4, 0x90
.asmWriteAllCommands49:
    vmovups ymm0, ymmword ptr [rcx + rbx]
    vmovups ymm1, ymmword ptr [rcx + rbx + 32]
    vmovups ymm2, ymmword ptr [rcx + rbx + 64]
    vmovups ymm3, ymmword ptr [rcx + rbx + 96]
    vmovups ymmword ptr [rbp + rbx - 96], ymm0
    vmovups ymmword ptr [rbp + rbx - 64], ymm1
    vmovups ymmword ptr [rbp + rbx - 32], ymm2
    vmovups ymmword ptr [rbp + rbx], ymm3
    sub     rbx, -128
    cmp     rdi, rbx
    jne     .asmWriteAllCommands49
    mov     rbp, qword ptr [rsp - 48]
    cmp     rax, rdi
    je      .asmWriteAllCommands57
    test    al, 112
    je      .asmWriteAllCommands55
.asmWriteAllCommands52:
    mov     rbx, rdi
    mov     rdi, rax
    and     rdi, -16
    .p2align    4, 0x90
.asmWriteAllCommands53:
    vmovups xmm0, xmmword ptr [rcx + rbx]
    vmovups xmmword ptr [r12 + rbx], xmm0
    add     rbx, 16
    cmp     rdi, rbx
    jne     .asmWriteAllCommands53
    cmp     rax, rdi
    je      .asmWriteAllCommands57
    jmp     .asmWriteAllCommands55
.asmWriteAllCommands58:
    xor     r8d, r8d
.asmWriteAllCommands59:
    mov     rax, r8
    pop     rbx
    pop     r12
    pop     r13
    pop     r14
    pop     r15
    pop     rbp
    vzeroupper
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
