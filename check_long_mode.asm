;long mode를 지원하는지를 확인합니다.
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
	test edx, 1 << 29
	jz .NoLongMode
	ret
	
;long mode를 지원하지 않으면 종료한다.
.NoLongMode:
	hlt