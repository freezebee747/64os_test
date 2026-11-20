BUILD   := build
ASM     := nasm
CC      := gcc
LD      := ld
OBJCOPY := objcopy

CFLAGS  := -m64 -ffreestanding -fno-pic -fno-pie -fno-stack-protector \
           -mno-red-zone -mgeneral-regs-only -fno-asynchronous-unwind-tables \
           -nostdlib -O2 -Wall -Wextra
LDFLAGS := -m elf_x86_64 -nostdlib -static -T linker.ld

ASM_INCLUDES := $(filter-out first_boot_sect.asm second_boot_sect.asm kernel_entry.asm,$(wildcard *.asm))

# 커널은 섹터 6부터 실린더0/헤드0 안에 있어야 함 (섹터 6~63 => 최대 58섹터)
MAX_KERNEL_SECTORS := 58

.PHONY: all run clean

all: $(BUILD)/os.img

$(BUILD):
	mkdir -p $@

$(BUILD)/stage1.bin: first_boot_sect.asm | $(BUILD)
	$(ASM) -f bin $< -o $@

$(BUILD)/kernel_entry.o: kernel_entry.asm | $(BUILD)
	$(ASM) -f elf64 $< -o $@

$(BUILD)/kernel.o: dummy_kernel.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/kernel.elf: $(BUILD)/kernel_entry.o $(BUILD)/kernel.o linker.ld
	$(LD) $(LDFLAGS) $(BUILD)/kernel_entry.o $(BUILD)/kernel.o -o $@

$(BUILD)/kernel.bin: $(BUILD)/kernel.elf
	$(OBJCOPY) -O binary $< $@

# 커널 크기에 맞춰 2단계가 읽을 섹터 수를 넘겨줌
$(BUILD)/stage2.bin: second_boot_sect.asm $(ASM_INCLUDES) $(BUILD)/kernel.bin
	@n=$$(( ($$(stat -c%s $(BUILD)/kernel.bin) + 511) / 512 )); \
	if [ $$n -gt $(MAX_KERNEL_SECTORS) ]; then echo "kernel too big: $$n sectors"; exit 1; fi; \
	echo "kernel = $$n sectors"; \
	$(ASM) -f bin -DKERNEL_SECTORS=$$n $< -o $@

# [섹터1: stage1][섹터2~5: stage2][섹터6~: kernel], 1.44MB로 패딩
$(BUILD)/os.img: $(BUILD)/stage1.bin $(BUILD)/stage2.bin $(BUILD)/kernel.bin
	cat $^ > $@
	truncate -s 1474560 $@

run: $(BUILD)/os.img
	qemu-system-x86_64 -drive format=raw,file=$<

clean:
	rm -rf $(BUILD)
