; /kernel/sc/about.asm
global cmd_about, str_about

section .data
str_about:      db 'about', 0
str_aboutmsg:   db 13, 10, '=== Krzeron OS ===', 13, 10, 10
                db 'Built with modular command architecture', 13, 10
                db 'A minimal x86 operating system', 13, 10, 10
				db 'Kernel version: 0.0.4 (Protected Mode)', 13, 10
				db 'Last update: 31-01-2026', 13, 10, 10
				db 'Written in pure x86 assembly', 13, 10
				db 'https://github.com/JamesAnanenkovic/KrzeronOperatingSystem', 13, 10, 0

section .text
cmd_about:
    push esi
    mov esi, str_aboutmsg
    call print_string_32
    pop esi
    ret
