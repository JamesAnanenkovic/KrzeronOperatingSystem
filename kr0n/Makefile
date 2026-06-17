# ==============================================================================
# kr0nos OS Build System v0.0.5
# Supports modular kernel with /kernel/sc/ and /drivers/ directories
# ==============================================================================

# Tools
NASM        = nasm
QEMU        = qemu-system-i386
NASMFLAGS   = -f bin -I kernel/ -Wall

# Directories
BOOT_DIR    = boot
KERNEL_DIR  = kernel
SC_DIR      = $(KERNEL_DIR)/sc
DRIVERS_DIR = drivers          # ← YENİ: Sürücü dizini
BUILD_DIR   = build

# Source files
BOOT_SRC    = $(BOOT_DIR)/boot.asm
KERNEL_SRC  = $(KERNEL_DIR)/kernel.asm

# ALL kernel dependencies (for proper incremental builds)
KERNEL_DEPS = $(KERNEL_SRC) \
              $(wildcard $(KERNEL_DIR)/*.asm) \
              $(wildcard $(SC_DIR)/*.asm) \
              $(wildcard $(DRIVERS_DIR)/*.asm)   # ← YENİ: Sürücü bağımlılıkları

# Output files
BOOT_BIN    = $(BUILD_DIR)/boot.bin
KERNEL_BIN  = $(BUILD_DIR)/kernel.bin
IMAGE       = $(BUILD_DIR)/kr0nos.img
HDD_IMG     = $(BUILD_DIR)/hdd.img
MAX_KERNEL_SIZE = 64512

# Colors (using printf for compatibility)
RED         = \033[0;31m
GREEN       = \033[0;32m
YELLOW      = \033[0;33m
CYAN        = \033[0;36m       # ← YENİ: Sürücüler için renk
NC          = \033[0m

# ==============================================================================
# Main Targets
# ==============================================================================

.PHONY: all run run-text debug clean info hdd

all: $(IMAGE) $(HDD_IMG)

all: $(IMAGE)

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)
	@printf "$(GREEN)[DIR]$(NC) Created build directory\n"

$(BOOT_BIN): $(BOOT_SRC) | $(BUILD_DIR)
	@printf "$(GREEN)[ASM]$(NC) Building bootloader...\n"
	$(NASM) $(NASMFLAGS) $< -o $@
	@if [ $$(stat -c%s "$@" 2>/dev/null || stat -f%z "$@") -gt 512 ]; then \
		printf "$(RED)[ERR]$(NC) Bootloader exceeds 512 bytes!\n"; \
		rm -f $@; \
		exit 1; \
	fi

$(KERNEL_BIN): $(KERNEL_DEPS) | $(BUILD_DIR)
	@printf "$(GREEN)[ASM]$(NC) Building kernel...\n"
	@printf "$(CYAN)[MOD]$(NC) Commands: $(notdir $(wildcard $(SC_DIR)/*.asm))\n"
	@printf "$(CYAN)[DRV]$(NC) Drivers:  $(notdir $(wildcard $(DRIVERS_DIR)/*.asm))\n"
	$(NASM) $(NASMFLAGS) $(KERNEL_SRC) -o $@
	@if [ $$(stat -c%s "$@" 2>/dev/null || stat -f%z "$@") -gt $(MAX_KERNEL_SIZE) ]; then \
		printf "$(RED)[ERR]$(NC) Kernel exceeds $(MAX_KERNEL_SIZE) bytes!\n"; \
		rm -f $@; \
		exit 1; \
	fi
	@printf "$(YELLOW)[INFO]$(NC) Kernel size: $$(stat -c%s "$@" 2>/dev/null || stat -f%z "$@") bytes\n"

$(IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	@printf "$(GREEN)[IMG]$(NC) Creating floppy image...\n"
	@dd if=/dev/zero of=$(IMAGE) bs=512 count=2880 status=none
	@dd if=$(BOOT_BIN) of=$(IMAGE) conv=notrunc bs=512 count=1 status=none
	@dd if=$(KERNEL_BIN) of=$(IMAGE) conv=notrunc bs=512 seek=1 status=none
	@printf "$(GREEN)[OK]$(NC) Build complete: $(IMAGE)\n"

$(HDD_IMG): | $(BUILD_DIR)
	@printf "$(YELLOW)[HDD]$(NC) Creating test HDD image...\n"
	@dd if=/dev/zero of=$(HDD_IMG) bs=512 count=2048 status=none
	@printf "$(GREEN)[HDD]$(NC) Writing pattern to HDD...\n"
	@python3 -c 'import sys; sys.stdout.buffer.write(bytes(range(256))*2)' | dd of=$(HDD_IMG) conv=notrunc bs=512 count=1 status=none
	@printf "$(GREEN)[HDD]$(NC) Setting boot signature...\n"
	@printf '\x55\xAA' | dd of=$(HDD_IMG) conv=notrunc bs=1 seek=510 status=none

# ==============================================================================
# Runtime Targets
# ==============================================================================

QEMU_HDD = -hda $(HDD_IMG)

run: $(IMAGE) $(HDD_IMG)
	@printf "$(GREEN)[RUN]$(NC) Starting kr0nos ( graphical mode )...\n"
	$(QEMU) -fda $(IMAGE) $(QEMU_HDD) -boot a

run-text: $(IMAGE) $(HDD_IMG)
	@printf "$(GREEN)[RUN]$(NC) Starting kr0nos ( text mode )...\n"
	$(QEMU) -fda $(IMAGE) $(QEMU_HDD) -boot a -nographic

debug: $(IMAGE) $(HDD_IMG)
	@printf "$(GREEN)[DBG]$(NC) Starting with serial debug...\n"
	$(QEMU) -fda $(IMAGE) $(QEMU_HDD) -boot a -serial stdio

gdb: $(IMAGE) $(HDD_IMG)
	@printf "$(GREEN)[GDB]$(NC) Starting QEMU GDB server on :1234...\n"
	@printf "$(YELLOW)[GDB]$(NC) Connect with: gdb target remote :1234\n"
	$(QEMU) -fda $(IMAGE) $(QEMU_HDD) -boot a -s -S -serial stdio

# ==============================================================================
# Utility Targets
# ==============================================================================

info: $(IMAGE)
	@printf "$(YELLOW)=== Build Information ===$(NC)\n"
	@printf "Bootloader: %s bytes\n" "$$(stat -c%s '$(BOOT_BIN)' 2>/dev/null || stat -f%z '$(BOOT_BIN)')"
	@printf "Kernel:     %s bytes\n" "$$(stat -c%s '$(KERNEL_BIN)' 2>/dev/null || stat -f%z '$(KERNEL_BIN)')"
	@printf "Image:      %s bytes\n" "$$(stat -c%s '$(IMAGE)' 2>/dev/null || stat -f%z '$(IMAGE)')"
	@printf "\n$(YELLOW)=== Command Modules ===$(NC)\n"
	@ls -1 $(SC_DIR)/*.asm 2>/dev/null | xargs -n1 basename | sed 's/^/  - /' || printf "  (none found)\n"
	@printf "\n$(CYAN)=== Driver Modules ===$(NC)\n"
	@ls -1 $(DRIVERS_DIR)/*.asm 2>/dev/null | xargs -n1 basename | sed 's/^/  - /' || printf "  (none found)\n"

hex: $(KERNEL_BIN)
	hexdump -C $(KERNEL_BIN) | less

disasm: $(KERNEL_BIN)
	ndisasm -b 32 -o 0x10000 $(KERNEL_BIN) | less

clean:
	@printf "$(RED)[CLN]$(NC) Cleaning build directory...\n"
	rm -rf $(BUILD_DIR)

check:
	@printf "$(YELLOW)[CHK]$(NC) Checking syntax...\n"
	@for file in $(KERNEL_DEPS) $(BOOT_SRC); do \
		$(NASM) $(NASMFLAGS) -o /dev/null $$file || exit 1; \
	done
	@printf "$(GREEN)[OK]$(NC) Syntax check passed\n"
