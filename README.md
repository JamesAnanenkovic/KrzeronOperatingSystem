# KrzeronOperatingSystem

Krzeron OS is a minimal operating system written entirely in x86 assembly.  
Its goal is to provide a small, understandable, and easily extendable OS kernel.

## Version History

| Version | Changes |
|---------|---------|
| 0.0.1   | Initial project setup |
| 0.0.2   | Added "about" command |
| 0.0.2.1 | Fixed "about" command |
| 0.0.2.2 | Boot and kernel fixes, improved Makefile, preparation for adding a filesystem |

## Features

- Minimal x86 Assembly-based kernel
- Simple command-line shell
  - `help` – Show available commands
  - `clear` – Clear the screen
  - `exit` – Shut down the OS
  - `about` – Show system information
- Structured build system (`Makefile`)
- Separate `build/` folder for build outputs
- Testable using QEMU


## Installation

1. Clone the repository:
git clone https://github.com/YOUR_USERNAME/KrzeronOperatingSystem.git
cd KrzeronOperatingSystem/kr0no/kr0nos_utd/kr0n

Build the project:
    make

Run in QEMU:
    make run
   
For debugging:
    make run-debug

To write to USB (CAUTION! This will erase the target disk):
    make usb DISK=/dev/sdX

Directory Structure:

kr0n/
├── boot/           # Bootloader source code
│   └── boot.asm
├── kernel/         # Kernel source code
│   └── kernel.asm
├── kernel/sc/      # Shell commands
│   └── uname.asm
├── build/          # Build outputs (auto-generated)
├── Makefile
└── README.md

## License

This project is licensed under the **GNU General Public License v3.0 (GPL-3.0)**.  
See the [LICENSE](LICENSE) file for details.
