section .text

extern print_uint, print_newline, exit
	
global _start
_start:
	mov rdi, 12345
	call print_uint
	call print_newline
	jmp exit
