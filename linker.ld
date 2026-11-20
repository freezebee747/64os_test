/* 커널을 2단계 부트로더가 읽어오는 물리 주소 0x10000에 배치 */
ENTRY(_start)

SECTIONS
{
    . = 0x10000;

    .text : {
        *(.text.entry)      /* _start가 반드시 맨 앞 */
        *(.text*)
    }
    .rodata : { *(.rodata*) }
    .data   : { *(.data*) }
    /* 주의: objcopy -O binary 는 .bss를 파일에 넣지 않음. 0으로 초기화하려면 커널에서 직접 지워야 함 */
    .bss    : { *(.bss*) *(COMMON) }

    /DISCARD/ : { *(.eh_frame*) *(.note*) *(.comment) }
}
