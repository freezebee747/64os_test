[bits 16]
; BIOS int 0x13, AH=0x02 (CHS 읽기). 실린더 0, 헤드 0 범위만 읽음
; 입력: ES:BX = 읽어올 메모리 주소
;       CL    = 시작 섹터 번호 (1부터 시작)
;       DH    = 읽을 섹터 수
;       DL    = 드라이브 번호
disk_load:
	pusha

	push dx
	mov ah, 0x02	;디스크를 읽기로 설정
	mov al, dh		;읽을 섹터 수
	mov ch, 0x00	;실린더 0
	mov dh, 0x00	;헤드 0

	int 0x13
	jc disk_error	;CF=1이면 읽기 실패

	pop dx
	cmp al, dh		;실제로 읽은 섹터 수 확인
	jne sectors_error

	popa
	ret

disk_error:
	mov bx, DISK_ERROR
	call print_string
	mov dl, ah		;AH = BIOS 에러 코드
	xor dh, dh
	call print_hex
	jmp disk_loop

sectors_error:
	mov bx, SECTORS_ERROR
	call print_string

disk_loop:
	cli
	hlt
	jmp disk_loop

DISK_ERROR: db "Disk read error", 0
SECTORS_ERROR: db "Incorrect number of sectors read", 0
