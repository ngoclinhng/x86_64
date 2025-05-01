%include "test_utils.asm"

section .data
    string_address db INPUT_STRING, 0
    
section .text

extern parse_uint, exit

global _start
_start:
	lea rdi, [string_address]

    PUSH_CALLEE_SAVED
	call parse_uint
    VERIFY_CALLEE_SAVED

    cmp rax, OUTPUT_NUMBER
    jne .error
    mov rdi, rdx
    jmp exit

.error:
    mov rdi, -1
    jmp exit
