연습용 os임니다

-현재는 부트섹터만 정의함. 이후에는 추가할 것

-코드는 osdev를 참고함

## 빌드 / 실행

필요: `nasm`, `gcc`, `binutils`(ld, objcopy), `qemu-system-x86_64`

```bash
make        # build/os.img 생성
make run    # QEMU로 부팅
```

디스크 이미지 배치

| 섹터 | 내용 | 로드 주소 |
|---|---|---|
| 1 | `first_boot_sect.asm` (1단계, 512B) | 0x7C00 |
| 2~5 | `second_boot_sect.asm` (2단계, 2048B) | 0x1000 |
| 6~ | 커널 (`kernel_entry.asm` + `dummy_kernel.c`) | 0x10000 |

부팅 흐름: 실시간 모드 → A20 → 커널 로드 → 32비트 보호 모드 → 롱 모드 지원 확인 → 페이징(첫 2MiB identity map) → 64비트 롱 모드 → `0x10000`의 커널로 점프
