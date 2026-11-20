; 커널 진입점. 링커 스크립트가 이 섹션을 0x10000 맨 앞에 배치함
[bits 64]
section .text.entry
global _start
extern kernel_main

_start:
	call kernel_main
.hang:
	cli
	hlt
	jmp .hang

; 실행 가능한 스택이 필요 없음을 링커에 알림 (ld 경고 제거)
section .note.GNU-stack noalloc noexec nowrite progbits
