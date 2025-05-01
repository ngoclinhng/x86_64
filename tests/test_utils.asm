%macro PUSH_CALLEE_SAVED 0
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
%endmacro

%macro VERIFY_CALLEE_SAVED 0
    cmp r15, [rsp]
    jne %%error

    cmp r14, [rsp + 8]
    jne %%error

    cmp r13, [rsp + 16]
    jne %%error

    cmp r12, [rsp + 24]
    jne %%error

    cmp rbp, [rsp + 32]
    jne %%error

    cmp rbx, [rsp + 40]
    jne %%error

    add rsp, 48
    jmp %%ok
    

    %%error:
    mov rdi, 1
    mov rax, 60
    syscall

    %%ok:
%endmacro
