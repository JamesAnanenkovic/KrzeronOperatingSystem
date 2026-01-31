; /kernel/sc/uname.asm - System information
global str_uname, cmd_uname

section .data
str_uname:      db 'uname', 0
msg_uname:      db 'kr0nos', 13,10,0           ; System name

section .text
cmd_uname:
    pusha
    
    ; Print system name
    mov esi, msg_uname
    call print_string_32
    
    popa
    ret
