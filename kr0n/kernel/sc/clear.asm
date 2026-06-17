; /kernel/sc/clear.asm
global cmd_clr, str_clr

section .data
str_clr:        db 'clr', 0

section .text
cmd_clr:
    call clear_screen_32
    ret
