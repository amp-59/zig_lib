    .intel_syntax noprefix
    .section    .rodata.cst16,"aM",@progbits,16
    .p2align    4
SPEC_0:
    .quad    4080
    .quad    4088
SPEC_1:
    .quad    20516608
    .quad    0
    .quad    0
    .quad    0
    .text
forwardToExecuteCloneThreaded:
    push            rbp
    mov             rbp, rsp
    push            rbx
    sub             rsp, 104
    mov             rbx, qword ptr [rbp + 24]
    vmovaps         xmm1, xmmword ptr [rip + SPEC_1]
    mov             r10, qword ptr [rbp + 16]
    lea             rax, [rip + executeCommandThreaded]
    vmovq           xmm0, rbx
    lea             r11, [rbx + 8]
    vmovaps         xmmword ptr [rbp - 96], xmm1
    vpbroadcastq    xmm0, xmm0
    vpaddq          xmm0, xmm0, xmmword ptr [rip + SPEC_0]
    vmovdqa         xmmword ptr [rbp - 80], xmm0
    vpxor           xmm0, xmm0, xmm0
    mov             qword ptr [rbp - 64], 0
    mov             qword ptr [rbp - 56], rbx
    mov             qword ptr [rbp - 48], 4096
    mov             qword ptr [rbp - 40], r11
    mov             qword ptr [rbp - 16], 0
    vmovdqa         xmmword ptr [rbp - 32], xmm0
    mov             qword ptr [rbx + 8], rax
    mov             qword ptr [rbx + 16], rdi
    mov             qword ptr [rbx + 24], rsi
    mov             qword ptr [rbx + 32], rdx
    mov             qword ptr [rbx + 40], rcx
    mov             qword ptr [rbx + 48], r10
    mov             byte ptr [rbx + 56], r8b
    mov             byte ptr [rbx + 57], r9b
    lea             rdi, [rbp - 96]
    mov             eax, 435
    mov             esi, 88
    syscall         # clone3
    test            rax, rax
    je              1f
    add             rsp, 104
    pop             rbx
    pop             rbp
    ret
1:
    xor             rbp, rbp
    sub             rsp, 4096
    mov             rax, rsp
    mov             rdi, qword ptr [rax + 16]
    mov             rsi, qword ptr [rax + 24]
    mov             rdx, qword ptr [rax + 32]
    mov             rcx, qword ptr [rax + 40]
    movzx           r8d, byte ptr [rax + 56]
    movzx           r9d, byte ptr [rax + 57]
    mov             rbx, qword ptr [rax + 48]
    mov             qword ptr [rsp], rbx
    call            qword ptr [rax + 8]
    mov             rax, 60
    mov             rdi, 0
    syscall         # exit
