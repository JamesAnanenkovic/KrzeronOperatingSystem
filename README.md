# kr0nos

kr0nos is a minimal operating system written entirely in x86 assembly.
Its goal is to provide a small, understandable, and easily extendable OS kernel.

## Version History

See [CHANGELOG](CHANGELOG.md) for full version history.

## Features

- Minimal x86 Assembly-based kernel (32-bit protected mode)
- Simple command-line shell
  - `help`     – Show available commands
  - `clear`    – Clear the screen
  - `exit`     – Shut down the OS (ACPI / HLT)
  - `about`    – Show OS information
  - `uname`    – Show system name
  - `read`     – Read and hex-dump a disk sector (experimental, ATA PIO LBA28)
  - `sysinfo`  – Show CPU info (CPUID) and RAM size (E820 via bootloader)
  - `uptime`   – Show system uptime in ticks
  - `sleep`    – Sleep for N ticks (`sleep <n>`)
- IDT with exception handlers (kernel panic on crash instead of reboot)
- PIT timer (IRQ0, 100Hz) with tick counter
- Serial I/O (COM1, 115200 baud) for text-mode terminal support
- Modular driver system (`drivers/`)
- Structured build system (`Makefile`)
- Testable using QEMU

## Build & Run

```bash
# Build
make

# Run in QEMU (graphical)
make run

# Run in terminal (text mode)
make run-text

# Debug mode (serial output)
make debug

# Syntax check
make check

# Clean build artifacts
make clean
```

## Project Structure

```
kr0n/
├── boot/boot.asm           # Bootloader (real mode → PM)
├── kernel/
│   ├── kernel.asm          # Main kernel (screen, keyboard, serial I/O, shell)
│   ├── pit.asm             # PIT driver (IRQ0, 100Hz tick)
│   ├── idt.asm             # IDT, exception handlers, PIC, IRQ subsystem
│   ├── commands.asm        # Command table and dispatcher
│   └── sc/                 # Shell commands
│       ├── help.asm
│       ├── clear.asm
│       ├── about.asm
│       ├── exit.asm
│       ├── uname.asm
│       ├── read.asm
│       ├── sysinfo.asm
│       ├── uptime.asm
│       └── sleep.asm
├── drivers/
│   ├── cpuid.asm           # CPU vendor/brand detection
│   └── memdetect.asm       # Memory size detection
├── build/                  # Build outputs (auto-generated)
├── Makefile
├── CHANGELOG.md
└── README.md
```

## License

GNU General Public License v3.0. See [LICENSE](LICENSE).
