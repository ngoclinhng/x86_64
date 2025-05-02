%include "test_utils.asm"

section .data
    lhs_str db STR1, 0
    rhs_str db STR2, 0
    
section .text

extern string_compare, exit

global _start
_start:
	lea rdi, [lhs_str]
    lea rsi, [rhs_str]
    mov rax, 1234567890         ; Garbage

    PUSH_CALLEE_SAVED
	call string_compare
    VERIFY_CALLEE_SAVED

    mov rdi, rax
    jmp exit
