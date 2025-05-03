%include "test_utils.asm"
    
section .bss
buffer: resb BUF_SIZE

section .data
expected: db EXPECTED, 0
    
section .text

extern read_word, string_compare, exit

global _start
_start:
    lea rdi, [buffer]
    mov rsi, BUF_SIZE

    PUSH_CALLEE_SAVED
	call read_word
    VERIFY_CALLEE_SAVED

    test rax, rax
    jz .overflow

    cmp rax, buffer
    jne .wrong_returned_value

    mov rdi, rax
    lea rsi, [expected]
    call string_compare

    test rax, rax
    jnz .wrong_string

    xor rdi, rdi
    jmp exit

.overflow:
    mov rdi, 1
    jmp exit

.wrong_returned_value:
    mov rdi, 2
    jmp exit

.wrong_string:
    mov rdi, 3
    jmp exit
