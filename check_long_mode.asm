[bits 32]
;long mode를 지원하는지를 확인합니다. (보호 모드에서 호출)
check_long_mode:
	call check_cpuid ;cpuid를 지원하는지 아닌지를 체크한다.
	test eax, eax
	jz .NoLongMode

	mov eax, 0x80000000
	cpuid
	cmp eax, 0x80000001
	jb .NoLongMode

	mov eax, 0x80000001
	cpuid
	test edx, 1 << 29    ; LM 비트
	jz .NoLongMode
	ret

;long mode를 지원하지 않으면 메시지를 출력하고 정지한다.
.NoLongMode:
	mov ebx, MSG_NO_LONG_MODE
	call print_string_pm
.halt:
	cli
	hlt
	jmp .halt

MSG_NO_LONG_MODE: db "ERROR: CPU does not support Long Mode       ", 0  ; 공백: 이전 메시지 덮어쓰기
