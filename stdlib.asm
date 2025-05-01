section .rodata	
	digits db '0123456789'
	
section .text

global exit
global string_length
global print_string, print_char, print_newline
global print_uint, print_int
global parse_uint

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

;; print_int(rdi: number)
print_int:
    test rdi, rdi
    jns print_uint
    
    push rdi
    mov dil, '-'
    call print_char
    pop rdi
    
    neg rdi
    jmp print_uint

;; Input: RDI = pointer to null-terminated string
;; Output: RAX = parsed number (0 if no digits found)
;;         RDX = count of characters parsed
;; Clobbers: RCX, RSI
parse_uint:
    xor rax, rax                ; Clear result (rax = 0)
    xor rcx, rcx                ; Clear temporary digit storage
    mov rsi, rdi                ; Copy string pointer to rsi

.loop:
    mov cl, byte [rsi]          ; Load current char
    test cl, cl                 ; Check for null terminator
    jz .end                     ; If null, we're done

    ; Skip whitespaces
    cmp cl, 9                   ; Skip HT \t
    je .next_char
    cmp cl, 10                  ; Skip new line \n
    je .next_char
    cmp cl, 13                  ; Skip CR \r
    je .next_char
    cmp cl, 32                  ; Skip SPACE
    je .next_char

    ; Check if char is a digit ('0' - '9')
    cmp cl, '0'
    jb .end
    cmp cl, '9'
    ja .end

    ; Convert ASCII digit to value
    sub cl, '0'

    ; Multiple current result by 10 and add new digit
    ; rax = rax * 10 + rcx
    lea rax, [rax + rax * 4]    ; rax *= 5
    add rax, rax                ; rax *= 2 (total 10x)
    add rax, rcx                ; Add new digit

.next_char:
    inc rsi
    jmp .loop
    
.end:
    sub rsi, rdi                ; Total characters processed
    mov rdx, rsi                ; Return count in rdx
    ret
    
    
	
	
	
