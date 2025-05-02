%include "test_utils.asm"
    
section .text

extern read_char, exit

global _start
_start:
    PUSH_CALLEE_SAVED
	call read_char
    VERIFY_CALLEE_SAVED

    cmp rax, EXPECTED
    jne .error

    xor rdi, rdi
    jmp exit

.error:
    mov rdi, -1
    jmp exit
