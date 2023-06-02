    .intel_syntax noprefix
    .p2align    4
forwardToExecuteCloneThreaded:
    push    rbp
    mov     rbp, rsp
    push    r15
    push    r14
    push    rbx
    sub     rsp, 88
    mov     r11, qword ptr [rbp + 16]
    mov     rax, qword ptr [rbp + 24]
    lea     r10, [rbp - 112]
    vxorps  xmm0, xmm0, xmm0
    mov     qword ptr [r10], 20516608
    and     qword ptr [r10 + 8], 0
    lea     rbx, [r11 + 4080]
    lea     r14, [r11 + 4064]
    lea     r15, [r11 + 4048]
    mov     qword ptr [r10 + 16], rbx
    mov     qword ptr [r10 + 24], r14
    and     qword ptr [r10 + 32], 0
    mov     qword ptr [r10 + 40], r11
    mov     qword ptr [r10 + 48], rax
    mov     qword ptr [r10 + 56], r15
    and     qword ptr [r10 + 80], 0
    vmovups xmmword ptr [r10 + 64], xmm0
    mov     qword ptr [rax + r11 - 16], offset executeCommandThreaded
    mov     qword ptr [rax + r11 - 64], rdi
    mov     qword ptr [rax + r11 - 56], rsi
    mov     qword ptr [rax + r11 - 48], rdx
    mov     qword ptr [rax + r11 - 40], rcx
    mov     qword ptr [rax + r11 - 32], r9
    mov     byte ptr [rax + r11 - 24], r8b
    push    88
    pop     rsi
    mov     eax, 435
    mov     rdi, r10
    syscall # clone3
    test    rax, rax
    je      1f
    add     rsp, 88
    pop     rbx
    pop     r14
    pop     r15
    pop     rbp
    ret
1:
    xor     rbp, rbp
    mov     rax, rsp
    mov     rdi, qword ptr [rax - 64]
    mov     rsi, qword ptr [rax - 56]
    mov     rdx, qword ptr [rax - 48]
    mov     rcx, qword ptr [rax - 40]
    movzx   r8d, byte ptr [rax - 24]
    mov     r9, qword ptr [rax - 32]
    call    qword ptr [rax - 16]
    mov     rax, 60
    mov     rdi, 0
    syscall # exit

