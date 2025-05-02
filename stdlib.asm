section .rodata	
	digits db '0123456789'
	
section .text

global exit
global string_length
global print_string, print_char, print_newline
global print_uint, print_int
global parse_uint, parse_int
global read_char, read_word
global string_compare

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

;; Parses an 64-bit unsigned integer from a null-terminated string.
;; Arguments:
;;   rdi - pointer to null-terminated string
;; Returns:    
;;   rax - parsed number (0 if no digits found)
;;   rdx - chars parsed
parse_uint:
    xor rax, rax                ; Clear result (rax = 0)
    xor rcx, rcx                ; Clear temporary digits storage
    mov rsi, rdi                ; Copy string pointer to rsi

.loop:
    movzx rcx, byte [rsi]       ; Load current char

    ; Check if current char is a digit ('0' - '9')
    cmp cl, '0'
    jb .end
    cmp cl, '9'
    ja .end

    ; Convert ASCII digit to value
    and cl, 0x0F

    ; Multiple current result by 10 and add new digit
    ; rax = rax * 10 + rcx
    lea rax, [rax + rax * 4]    ; rax *= 5
    add rax, rax                ; rax *= 2 (total 10x)
    add rax, rcx                ; Add new digit

    ; Move to next char
    inc rsi
    jmp .loop
    
.end:
    sub rsi, rdi                ; Total characters processed
    mov rdx, rsi                ; Return count in rdx
    ret

;; Parses an 64-bit signed integer from a null-terminated string.    
;; Arguments:
;;   rdi - null-terminated string
;; Returns:
;;   rax - parsed number (0 if invalid)
;;   rdx - chars parsed including sign char ('+'/'-') if present
parse_int:
    movzx rcx, byte [rdi]

    cmp cl, '+'
    je .plus
    cmp cl, '-'
    je .minus
    jmp parse_uint

.plus:
    push 0
    jmp .digits
    
.minus:
    push -1
    
.digits:
    inc rdi
    call parse_uint
    pop rcx

    test rdx, rdx
    jz .done
    inc rdx

    test rcx, rcx
    jns .done
    neg rax

.done:
    ret

;; Reads one character (1 byte) from stdin
;; Returns:
;;   rax - character read or 0 on EOF/error
read_char:
    push 0

    ; sys_read(fd=0, buf=rsp, count=1)
    xor rax, rax
    xor rdi, rdi
    mov rsi, rsp
    mov rdx, 1
    syscall

    pop rax
    ret

;; Reads next word from stdin.
;; Arguments:
;;   rdi - buffer address
;;   rsi - buffer size
;; Returns:
;;   rax - buffer address on success, 0 if word is too big
read_word:
    ; TODO
    ret

;; Compares two null-terminated strings
;; Arguments:
;;  rdi - pointer to first string (s1)
;;  rsi - pointer to second string (s2)
;; Returns:
;;  rax = comprison result (0 if equal, positive if s1 > s2,
;;        negative of s1 < s2)
string_compare:
    pushfq                      ; Save rflags (including DF)
    cld                         ; Clear direction flag (DF = 0 for forward)

.loop:
    cmpsb                       ; Compare byte at [rsi] with [rdi], increment
    jne .return_diff            ; both.

    test byte [rdi - 1], 0xFF   ; Check if last byte was null
    jz .return_equal

    jmp .loop

.return_diff:
    mov rax, -1                 ; Default -1 (s1 < s2)
    jc .greater                 ; If CF = 1, s2 - s1 < 0
    popfq                       ; Restore rflags
    ret    
    
.greater:
    mov rax, 1                  ; Return 1 (s1 > s2)
    popfq                       ; Restore rflags
    ret

.return_equal:
    xor rax, rax                ; Return 0 (s1 = s2)
    popfq                       ; Restore rflags
    ret
