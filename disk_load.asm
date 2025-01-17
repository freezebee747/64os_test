[bits 16]
disk_load:
	pusha
	
	push dx
	mov ah, 0x02	;디스크를 읽기로 설정
	mov al, dh
	mov cl, 0x02
	
	mov ch, 0x00
	mov dh, 0x00
	
	mov es, bx
	mov bx, 0x0000
	
	int 0x13
	
	pop dx
	cmp al, dh
	jne sectors_error
	
	popa
	ret
	
disk_error:
    mov bx, DISK_ERROR
	call print_string
	mov dh, ah
	call print_hex
	jmp disk_loop
	
sectors_error:
    mov bx, SECTORS_ERROR
    call print_string

disk_loop:
    jmp $

DISK_ERROR: db "Disk read error", 0
SECTORS_ERROR: db "Incorrect number of sectors read", 0
