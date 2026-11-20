[bits 32]
;CPUID 지원 여부 체크 (보호 모드에서 호출)
;반환: EAX = 1 지원, 0 미지원
check_cpuid:
	; EFLAGS를 EAX로 복사
	pushfd
	pop eax

	;ECX에 복사해 놓는다.(원본값 저장)
	mov ecx, eax

	;ID비트(21)를 토글한다.
	xor eax, 1 << 21

	; 수정된 값을 EFLAGS로 로드
	push eax
	popfd

	;다시 EFLAGS를 읽어옴
	pushfd
	pop eax

	;원래 EFLAGS 복원
	push ecx
	popfd

	;원본 값과 비교: 바뀌지 않았으면 CPUID 미지원
	xor eax, ecx
	jz .NoCPUID
	mov eax, 1
	ret

.NoCPUID:
	xor eax, eax
	ret
