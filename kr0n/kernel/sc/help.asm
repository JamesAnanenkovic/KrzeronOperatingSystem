; /kernel/sc/help.asm
global cmd_help, str_help

section .data
str_help:       db 'help', 0
str_helpmsg:    db 'Available commands:', 13, 10
                db '  help   - Show this help message', 13, 10
                db '  about  - Show OS information', 13, 10
                db '  clear  - Clear the screen', 13, 10
                db '  uname  - Shows OS that you are using right now', 13, 10
                db '  read   - Try to read a sector (exprimental)', 13, 10
                db '  exit   - Halt the system', 13, 10, 0

section .text
cmd_help:
    push esi
    mov esi, str_helpmsg
    call print_string_32
    pop esi
    ret
