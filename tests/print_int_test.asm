%include "test_utils.asm"
    
section .text

extern print_int, exit

global _start
_start:
	mov rdi, TEST_VALUE
    PUSH_CALLEE_SAVED
	call print_int
    VERIFY_CALLEE_SAVED
	xor rdi, rdi
	jmp exit
