; 32비트 보호 모드 -> 64비트 롱 모드 전환
; (OSDev의 "real mode에서 바로 long mode" 예제를 보호 모드에서 쓰도록 32비트로 고침)
[bits 32]

%define PAGE_PRESENT    (1 << 0)
%define PAGE_WRITE      (1 << 1)

%define CODE_SEG_LONG     0x0008
%define DATA_SEG_LONG     0x0010

PAGING_BASE equ 0x9000          ; PML4/PDPT/PD/PT 4개 = 16KiB (0x9000 ~ 0xCFFF)

ALIGN 4
IDT:
    .Length       dw 0
    .Base         dd 0

; 첫 2MiB를 identity map 한 뒤 롱 모드로 들어간다. 돌아오지 않음.
switch_to_lm:
    ; 16KiB 버퍼를 0으로 채움 (ES = 평면 데이터 세그먼트)
    mov edi, PAGING_BASE
    mov ecx, 0x1000                   ; 16KiB / 4
    xor eax, eax
    cld
    rep stosd
    mov edi, PAGING_BASE

    ; PML4[0] -> PDPT
    lea eax, [edi + 0x1000]
    or eax, PAGE_PRESENT | PAGE_WRITE
    mov [edi], eax

    ; PDPT[0] -> PD
    lea eax, [edi + 0x2000]
    or eax, PAGE_PRESENT | PAGE_WRITE
    mov [edi + 0x1000], eax

    ; PD[0] -> PT
    lea eax, [edi + 0x3000]
    or eax, PAGE_PRESENT | PAGE_WRITE
    mov [edi + 0x2000], eax

    ; PT: 512개 엔트리로 0 ~ 2MiB identity map
    lea ebx, [edi + 0x3000]
    mov eax, PAGE_PRESENT | PAGE_WRITE
.LoopPageTable:
    mov [ebx], eax
    add eax, 0x1000
    add ebx, 8
    cmp eax, 0x200000
    jb .LoopPageTable

    ; PIC의 모든 IRQ 마스크
    mov al, 0xFF
    out 0xA1, al
    out 0x21, al

    lidt [IDT]                        ; 길이 0인 IDT: 예외가 나면 triple fault

    ; CR4.PAE(bit5) | CR4.PGE(bit7)
    mov eax, cr4
    or eax, (1 << 5) | (1 << 7)
    mov cr4, eax

    mov cr3, edi                      ; CR3 = PML4

    ; EFER.LME 설정
    mov ecx, 0xC0000080
    rdmsr
    or eax, (1 << 8)
    wrmsr

    ; 페이징 활성화 (PE는 이미 켜져 있음) -> 호환 모드
    mov eax, cr0
    or eax, (1 << 31)
    mov cr0, eax

    lgdt [GDT.Pointer]
    jmp CODE_SEG_LONG:LongMode        ; 64비트 코드 세그먼트로 far jump

; 64비트용 GDT
GDT:
.Null:
    dq 0x0000000000000000             ; Null Descriptor
.Code:
    dq 0x00209A0000000000             ; 64-bit code descriptor (exec/read)
.Data:
    dq 0x0000920000000000             ; 64-bit data descriptor (read/write)
.End:

ALIGN 4
    dw 0                              ; 아래 dd가 4바이트 정렬되도록 패딩
.Pointer:
    dw .End - GDT - 1                 ; GDT 크기 - 1
    dd GDT

[bits 64]
LongMode:
    mov ax, DATA_SEG_LONG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov rsp, 0x90000

    jmp BEGIN_LM
