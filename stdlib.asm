section .rodata	
	digits db '0123456789'
	
section .text

global exit
global string_length
global print_string, print_char, print_newline
global print_uint

;; exit(rdi: exit_code)
exit:
	mov rax, 60
	syscall

;; string_length(rdi: string) -> rax: length
string_length:
	xor rax, rax
.loop:
	cmp byte [rdi + rax], 0
	je .done
	inc rax
	jmp .loop
.done:
	ret

;; print_string(rdi: string)
print_string:
	push rdi
	call string_length
	pop rsi
	mov rdx, rax
	mov rax, 1
	mov rdi, 1
	syscall
	ret

;; print_char(dil: char)
print_char:
	push rdi
	mov rsi, rsp
	mov rdi, 1
	mov rdx, 1
	mov rax, 1
	syscall
	pop rdi
	ret

;; print_newline()
print_newline:
	mov dil, 0xA
	jmp print_char

;; print_uint(rdi: number)
print_uint:
	mov rsi, rsp
	sub rsp, 24
	dec rsi
	mov byte [rsi], 0
	xor rcx, rcx	
	mov r8, 10
	mov rax, rdi
.loop:
	xor rdx, rdx
	div r8
	mov dl, [digits + rdx]
	dec rsi
	mov [rsi], dl
	inc rcx
	test rax, rax
	jnz .loop
.print:
	mov rax, 1
	mov rdi, 1
	mov rdx, rcx
	syscall
.done:
	add rsp, 24
	ret
	
	
	
