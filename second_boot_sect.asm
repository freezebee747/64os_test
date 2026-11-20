[org 0x1000]
[bits 16]

; 디스크 이미지 배치: [섹터1: 1단계] [섹터2~5: 2단계(이 파일)] [섹터6~: 커널]
KERNEL_SEG          equ 0x1000   ; 실시간 모드 세그먼트 0x1000:0x0000 = 물리 0x10000 (64KB)
KERNEL_ADDR         equ 0x10000  ; 롱 모드에서 점프할 물리(=가상, identity map) 주소
KERNEL_START_SECTOR equ 6        ; CHS 섹터 번호(1부터 시작). 1 + 4(2단계) 다음
%ifndef KERNEL_SECTORS
KERNEL_SECTORS      equ 8        ; Makefile이 커널 크기에 맞춰 -DKERNEL_SECTORS=N 으로 넘겨줌
%endif

Main:
;세그먼트/스택 초기화
	cli
	xor ax, ax
	mov ss, ax
	mov sp, Main         ; 스택은 0x1000 아래로 자람
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	sti
	cld

	mov [BOOT_DRIVE], dl

	mov bx, MSG_REAL_MODE
	call print_string

	call check_a20
	cmp ax, 0x0
	jne .LoadKernel
	call enable_A20

.LoadKernel:
	call load_kernel

	mov bx, MSG_SUCC_KERNEL
	call print_string

	; 보호 모드로 전환. 돌아오지 않으므로 call이 아니라 jmp
	jmp switch_to_pm

[bits 16]
load_kernel:
	pusha
	push es

	mov bx, MSG_LOAD_KERNEL
	call print_string

	; ES:BX = 0x1000:0x0000 (물리 0x10000)에 커널을 읽어온다
	mov ax, KERNEL_SEG
	mov es, ax
	xor bx, bx
	mov cl, KERNEL_START_SECTOR
	mov dh, KERNEL_SECTORS
	mov dl, [BOOT_DRIVE]
	call disk_load

	pop es
	popa
	ret

[bits 32]
; switch_to_pm.asm의 init_pm에서 jmp로 들어옴
BEGIN_PM:
	mov ebx, MSG_PROT_MODE
	call print_string_pm

	call check_long_mode     ; 지원하지 않으면 메시지 출력 후 정지

	; 롱 모드로 전환. 역시 돌아오지 않음
	jmp switch_to_lm

[bits 64]
; switch_lm.asm의 LongMode에서 jmp로 들어옴
BEGIN_LM:
	; 화면 전체를 검은 배경 공백으로 지움
	mov edi, 0xB8000
	mov rcx, 500                       ; 80*25*2 바이트 / 8
	mov rax, 0x0720072007200720
	rep stosq

	; 두 번째 줄에 롱 모드 진입 메시지 출력
	mov rdi, 0xB8000 + 160
	mov rbx, MSG_LONG_MODE
	call print_string_long

	; 커널로 점프 (0x10000)
	mov rax, KERNEL_ADDR
	jmp rax

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

BOOT_DRIVE:			db 0
MSG_PROT_MODE:		db "Successfully landed in 32-bit Protected Mode",0
MSG_LOAD_KERNEL:	db "Loading kernel into memory",0
MSG_SUCC_KERNEL:	db "Kernel Successfully Loaded in memory", 0
MSG_REAL_MODE:		db "Started in 16-bit Real Mode",0
MSG_LONG_MODE:		db "Successfully landed in Long Mode",0

;패딩: 1단계가 정확히 4섹터(2048바이트)를 읽음. 넘치면 어셈블 에러가 남
	times 2048-($-$$) db 0
