# Makefile for Kr0nOS (Pure Assembly)

# Assembler
ASM = nasm
ASMFLAGS = -f bin

# --- Build klasörü ---
BUILD_DIR := build

# --- Kaynak klasörleri ---
BOOT_DIR := boot
KERNEL_DIR := kernel

# --- Kaynak dosyalar (source code) ---
BOOT_SRC   := $(BOOT_DIR)/boot.asm
KERNEL_SRC := $(KERNEL_DIR)/kernel.asm

# --- Çıktı dosyaları (machine code) ---
BOOTLOADER := $(BUILD_DIR)/boot.bin
KERNEL     := $(BUILD_DIR)/kernel.bin
OS_IMG     := $(BUILD_DIR)/kr0nos.img

# --- Default target ---
all: $(OS_IMG)

# --- Create bootable floppy image (1.44MB) ---
$(OS_IMG): $(BOOTLOADER) $(KERNEL)
	dd if=/dev/zero of=$(OS_IMG) bs=512 count=2880
	mkfs.fat -F 12 -n "KR0NOS" $(OS_IMG)
	dd if=$(BOOTLOADER) of=$(OS_IMG) conv=notrunc bs=512 count=1
	dd if=$(KERNEL) of=$(OS_IMG) seek=1 conv=notrunc

# --- Build bootloader ---
$(BOOTLOADER): $(BOOT_SRC) | $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) -o $@ $<

# --- Build kernel ---
$(KERNEL): $(KERNEL_SRC) | $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) -o $@ $<

# --- Run in QEMU ---
run: $(OS_IMG)
	qemu-system-i386 -fda $(OS_IMG) -boot a

# --- Run in QEMU with debug ---
run-debug: $(OS_IMG)
	qemu-system-i386 -fda $(OS_IMG) -boot a -d int -no-reboot -D $(BUILD_DIR)/qemu_debug.log

# --- Create build directory if missing ---
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# --- Create a bootable USB (WARNING: Be careful!) ---
# Usage: make usb DISK=/dev/sdX
usb: $(OS_IMG)
	sudo dd if=$(OS_IMG) of=$(DISK) bs=4M status=progress
	sync

# --- Clean build files ---
clean:
	rm -rf $(BUILD_DIR)

# --- Help ---
help:
	@echo "Kr0nos OS Build System"
	@echo "Available targets:"
	@echo "  all         - Build everything (default)"
	@echo "  run         - Run in QEMU"
	@echo "  run-debug   - Run in QEMU with interrupt debugging"
	@echo "  clean       - Remove build files"
	@echo "  help        - Show this help"
	@echo "  usb         - Create bootable USB (set DISK=/dev/sdX)"

.PHONY: all run run-debug clean help usb
