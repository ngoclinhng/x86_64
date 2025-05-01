%include "test_utils.asm"

section .data
    string_address db INPUT_STRING, 0 ; null-terminator

section .text

extern string_length, exit

global _start:
_start:
    lea rdi, [string_address]
    PUSH_CALLEE_SAVED
    call string_length
    VERIFY_CALLEE_SAVED
    mov rdi, rax
    jmp exit
    
    
