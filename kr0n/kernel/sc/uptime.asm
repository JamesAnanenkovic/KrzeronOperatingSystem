; /kernel/sc/uptime.asm
global cmd_uptime, str_uptime

section .data
str_uptime:     db 'uptime', 0
str_uptime_msg: db 'System running for ', 0
str_ticks:      db ' ticks (100Hz)', 13, 10, 0

section .text
cmd_uptime:
    mov esi, str_uptime_msg
    call print_string_32
    call get_tick_count
    call print_number_32
    mov esi, str_ticks
    call print_string_32
    ret
