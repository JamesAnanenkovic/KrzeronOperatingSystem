; /kernel/sc/clear.asm
global cmd_clear, str_clear

section .data
str_clear:      db 'clear', 0

section .text
cmd_clear:
    call clear_screen_32
    ret
