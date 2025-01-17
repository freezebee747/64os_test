[org 0x1000]
KERNEL_ENTRY equ 0x1000 ; -> 0x1000 : 0x0000 1MB를 가리키도록 설정
FREE_SPACE equ 0x9000

Main:
;세그먼트 초기화
	xor ax, ax
	mov ss, ax
	mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    cld
	
	mov [BOOT_DRIVE], dl
	
	mov bx, MSG_REAL_MODE
    call print_string

    mov sp, Main
	
	call check_a20

	cmp ax, 0x0
	jne .LoadKernel
	call enable_A20

.LoadKernel:

	call load_kernel
	
	mov bx, MSG_SUCC_KERNEL
    call print_string
	
	call switch_to_pm
	
	call switch_to_lm
	jmp $

%include "checkA20.asm"
%include "enableA20.asm"
%include "print_string.asm"
%include "print_hex.asm"
%include "print_string_pm.asm"
%include "print_hex_pm.asm"
%include "print_string_long.asm"
%include "print_hex_long.asm"
%include "disk_load.asm"
%include "switch_to_pm.asm"
%include "switch_lm.asm"
%include "check_long_mode.asm"
%include "check_cpuid.asm"
%include "gdt.asm"

[bits 16]
load_kernel:
	pusha
	mov bx, MSG_LOAD_KERNEL
	call print_string
	
	mov bx, KERNEL_ENTRY
	mov dh, 8
	mov dl, [BOOT_DRIVE]
	call disk_load
	
	popa
	ret
	
[bits 32]
BEGIN_PM:

	mov ebx, MSG_PROT_MODE
    call print_string_pm
	
	ret
	
[bits 64]
BEGIN_LM:

  ; Blank out the screen to a blue color.
    mov edi, 0xB8000
    mov rcx, 500                      ; Since we are clearing uint64_t over here, we put the count as Count/4.
    mov rax, 0x1F201F201F201F20       ; Set the value to set the screen to: Blue background, white foreground, blank spaces.
    rep stosq                         ; Clear the entire screen. 
 
    ; Display "Hello World!"
    mov edi, 0x00b8000              
    
    mov rax, 0x1F6C1F6C1F651F48    
    mov [edi],rax
    
    mov rax, 0x1F6F1F571F201F6F
    mov [edi + 8], rax

    mov rax, 0x1F211F641F6C1F72
    mov [edi + 16], rax
	
	jmp $


BOOT_DRIVE:			db 0
MSG_PROT_MODE:		db "Successfully landed in 32-bit Protected Mode",0
MSG_LOAD_KERNEL:	db "Loading kernel into memory",0
MSG_SUCC_KERNEL:	db "Kernel Successfully Loaded in memory", 0
MSG_REAL_MODE:		db "Started in 16-bit Real Mode",0
MSG_LONG_MODE:		db "Successfully landed in Long Mode",0

;패딩
	times 2046-($-$$) db 0
	dw 0xaa55