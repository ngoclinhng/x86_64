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

;; Reads a word from stdin into a buffer, skipping leading whitespace
;; characters, and null-terminates the word.
;;
;; Arguments:
;;   rdi: Address of the output buffer (char*)
;;   rsi: Size of the buffer in bytes, including space for null terminator.
;;
;; Returns:
;;   rax: Address of the buffer (rdi) if a word is successfully read and
;;        stored 0 if:
;;        - Buffer size < 2 (no room for char + '\0')
;;        - Word is too long for buffer (excluding null terminator)    
;;        - EOF or error occurs while reading from stdin
;;
;; Behavior:
;;   - Skips leading whitespace: space (0x20), tab (0x09), newline (0x0A),
;;     carriage return (0x0D).
;;   - Reads a word (sequence of characters excluding space) until a space,
;;     EOF, or error.
;;   - Null-terminates the word in the buffer.
;;   - Uses a 64-byte stack-allocated buffer to minimize sys_read calls.
read_word:
    push rbx                    ; Callee-saved, used for counter
    push r12                    ; Callee-saved, used for buffer address
    push r13                    ; Callee-saved, used for buffer size
    push r14                    ; Callee-saved, used for buffer position
    push r15                    ; Callee-saved, used for bytes read

    sub rsp, 64                 ; Allocate 64-byte buffer on stack

    xor rbx, rbx                ; Initialize character count
    mov r12, rdi                ; Output buffer address
    mov r13, rsi                ; Output buffer size
    xor r14, r14                ; Initialize buffer position (pos)
    xor r15, r15                ; Initialzie bytes read (bytes_read)

    ; Check if buffer size is too small
    ; size < 2, no room for 1 char + '\0'
    cmp r13, 2
    jl .too_small

.skip_whitespace:
    ; Check if buffer is exhausted (pos >= bytes_read)
    cmp r14, r15
    jge .refill_buffer

    ; Load next byte from buffer
    mov al, byte [rsp + r14]
    inc r14                     ; Advance position

    ; Check if byte is whitespace: Space (0x20), Tab (0x09), Newline (0x0A),
    ; or Carriage return (0x0D)
    cmp al, 0x20
    je .skip_whitespace
    cmp al, 0x09
    je .skip_whitespace
    cmp al, 0x0A
    je .skip_whitespace
    cmp al, 0x0D
    je .skip_whitespace

    ; Non-whitespace character found (al):
    ;   - Check for buffer overflow
    ;   - Store the char (al)
    ;   - Read next byte. Whitespace? YES - end, NO - repeat
.store_char:
    ; Check if buffer has space for null terminator
    mov rcx, r13                ; rcx = input buffer size
    dec rcx                     ; rcx -= 1
    cmp rbx, rcx                ; is current char count >= size - 1
    jae .too_big                ; Buffer overflow

    ; Store char (al)
    mov byte [r12 + rbx], al
    inc rbx

    ; Check if buffer is exhausted before reading next byte
    cmp r14, r15
    jge .refill_buffer

    ; Load next byte from buffer into al and check for
    ; termination
.read_char:
    mov al, byte [rsp + r14]    ; Load next byte
    inc r14

    ; Check if byte is whitespace: Space (0x20), Tab (0x09), Newline (0x0A),
    ; or Carriage return (0x0D). If it is, we're done.
    cmp al, 0x20
    je .end_word
    cmp al, 0x09
    je .end_word
    cmp al, 0x0A
    je .end_word
    cmp al, 0x0D
    je .end_word

    ; Else store the char and continue
    jmp .store_char

.refill_buffer:
    ; Read up to 64 bytes from stdin
    xor rax, rax                ; sys_read (0)
    xor rdi, rdi                ; stdin (0)
    mov rsi, rsp                ; buffer address
    mov rdx, 64                 ; Read up to 64 bytes
    syscall

    ; Check for error or EOF (rax <= 0)
    test rax, rax
    jle .eof_or_error

    ; Update byte_reads and reset pos
    mov r15, rax                ; bytes_read = rax
    xor r14, r14                ; pos = 0

    ; Either jump back to .skip_whitespace (count = 0)
    ; or .read_word (count > 0)
    test rbx, rbx
    jz .skip_whitespace
    jmp .read_char

.too_small:
.too_big:
.eof_or_error:
    xor rax, rax                ; Return = 0
    add rsp, 64                 ; Deallocate stack buffer
    pop r15                     ; Restore r15
    pop r14                     ; Restore r14
    pop r13                     ; Restore r13
    pop r12                     ; Restore r12
    pop rbx                     ; Restore rbx
    ret

.end_word:
    mov byte [r12 + rbx], 0     ; Null terminator
    mov rax, r12                ; Address of the buffer
    add rsp, 64                 ; Deallocate stack buffer
    pop r15                     ; Restore r15
    pop r14                     ; Restore r14
    pop r13                     ; Restore r13
    pop r12                     ; Restore r12
    pop rbx                     ; Restore rbx
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
