# kr0nos

kr0nos is a minimal operating system written entirely in x86 assembly.
Its goal is to provide a small, understandable, and easily extendable OS kernel.

## Version History

| Version | Changes |
|---------|---------|
| 0.0.1   | Initial project setup |
| 0.0.2   | Added "about" command |
| 0.0.2.1 | Fixed "about" command |
| 0.0.2.2 | Boot and kernel fixes, improved Makefile, preparation for filesystem |
| 0.0.3   | Kernel refactored, command system fixed, added "read" and "uname" |
| 0.0.3.1 | Exit command fixed (QEMU compat) |
| 0.0.4   | 16-bit real mode → 32-bit protected mode |
| 0.0.5   | Added `sysinfo` command (CPU + RAM), memory detection moved to bootloader, unknown command error message |
| 0.0.5.1 | Added IDT with exception handlers, PIC remapped and masked, kernel panic messages |
| 0.0.5.2 | Added serial I/O (COM1, 115200 baud), ANSI escape clear, dual PS/2 + serial input |

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
- IDT with exception handlers (kernel panic on crash instead of reboot)
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
│   ├── idt.asm             # IDT, exception handlers, PIC
│   ├── commands.asm        # Command table and dispatcher
│   └── sc/                 # Shell commands
│       ├── help.asm
│       ├── clear.asm
│       ├── about.asm
│       ├── exit.asm
│       ├── uname.asm
│       ├── read.asm
│       └── sysinfo.asm
├── drivers/
│   ├── cpuid.asm           # CPU vendor/brand detection
│   └── memdetect.asm       # Memory size detection
├── build/                  # Build outputs (auto-generated)
├── Makefile
└── README.md
```

## License

GNU General Public License v3.0. See [LICENSE](LICENSE).
