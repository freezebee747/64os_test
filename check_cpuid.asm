;CPUID체크
check_cpuid:
	; 스텍에서 FLAGS를 EAX로 복사한다.
	pushfq
	pop rax
	
	;ECX에 복사해 놓는다.(원본값 저장)
	mov rcx, rax
	
	;ID비트로 토글한다.
	xor rax, 1 << 21
	
	; 수정된 값을 스택에 저장, 그후 EFLAGS로드
    push rax
    popfq
	
	;다시 EFLAGS를 스택에 저장
	pushfq
	pop rax
	
	;원본 값과 비교
	xor rax, rcx 
	jz .NoCPUID
	mov rax, 1
    ret

;더미 코드
.NoCPUID:
	mov rax, 0
	ret