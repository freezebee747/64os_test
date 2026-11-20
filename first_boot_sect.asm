[org 0x7c00]
[bits 16]
SEC_BOOT_ENTRY equ 0x1000
STAGE2_SECTORS equ 4        ; second_boot_sect.bin = 2048바이트 = 4섹터

start:
;세그먼트/스택 초기화 (BIOS가 DS/ES/SS를 0으로 넘겨준다는 보장이 없음)
	cli
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov bp, 0x9000
	mov sp, bp
	sti

	mov [BOOT_DRIVE], dl

	; 2단계 부트로더 로드 메시지 출력
	mov si, MSG_LOAD_STAGE2
	call print_string

;부팅과정을 2번째 부트로더에 위임
	; 2단계 부트로더 로드 (ES:BX = 0x0000:0x1000)
	mov bx, SEC_BOOT_ENTRY
	mov dh, STAGE2_SECTORS
	mov dl, [BOOT_DRIVE]
	call disk_load

	mov si, MSG_LOAD_STAGE3
	call print_string

	; 2단계 부트로더로 점프 (DL = 부트 드라이브를 넘겨줌)
	mov dl, [BOOT_DRIVE]
	jmp 0x0000:SEC_BOOT_ENTRY

;필요함수들
;문자열 출력 함수
print_string:
	mov ah, 0x0E
.next_char:
	lodsb
	or al, al
	jz .print_nl
	int 0x10
	jmp .next_char
.print_nl:
	mov al, 0x0a ; newline char
	int 0x10
	mov al, 0x0d ; carriage return
	int 0x10
.done:
	ret

; BIOS 디스크 로드 함수
disk_load:
	pusha                 ; 레지스터 상태 저장
	mov ah, 0x02          ; BIOS: 섹터 읽기
	mov al, dh            ; 읽을 섹터 수
	mov ch, 0             ; Cylinder = 0
	mov cl, 0x02          ; Sector = 2 (부트 섹터 다음)
	mov dh, 0             ; Head = 0
	mov dl, [BOOT_DRIVE]  ; 부트 드라이브

	int 0x13              ; BIOS 디스크 읽기 호출
	jc disk_error         ; CF=1(에러) 시 disk_error로 이동
	popa                  ; 레지스터 복원
	ret                   ; 성공 시 반환

disk_error:
	mov si, MSG_DISK_ERROR
	call print_string
.halt:
	cli                   ; 인터럽트를 끄지 않으면 hlt에서 다시 깨어남
	hlt
	jmp .halt

;상수 정의
BOOT_DRIVE db 0
MSG_LOAD_STAGE2 db "Loading stage 2...", 0
MSG_LOAD_STAGE3 db "Jumping stage 2...", 0
MSG_DISK_ERROR db "Disk read error", 0

	;패딩
	times 510-($-$$) db 0
	dw 0xaa55
