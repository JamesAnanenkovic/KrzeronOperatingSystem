# Changelog

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
| 0.0.6   | Added PIT (IRQ0, 100Hz), IRQ subsystem, tick counter, `uptime` command |
| 0.0.6.1 | Added `sleep` command with arg parsing, improved command dispatcher |
| 0.0.7   | Interrupt-driven keyboard (IRQ1, buffer, hlt), polling replaced |
| 0.0.7.1 | Centralized version define, sysinfo shows version |
| 0.0.7.2 | Added version, clr, reboot commands; removed clear |
