[bits 64]
; 입력: RBX = 문자열 주소, RDI = 출력할 비디오 메모리 주소
print_string_long:
    push rdx
    push rax
    push rbx
    mov rdx, rdi
print_string_long_loop:
    mov al, [rbx]
    mov ah, 0x0f

    cmp al, 0
    je print_string_long_done

    mov [rdx], ax

    add rbx, 1
    add rdx, 2

    jmp print_string_long_loop

print_string_long_done:
    pop rbx
    pop rax
    pop rdx

    ret
