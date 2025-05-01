section .text

extern print_uint, print_newline, exit

global _start
_start:
	mov rdi, TEST_VALUE
	call print_uint

	xor rdi, rdi
	jmp exit
