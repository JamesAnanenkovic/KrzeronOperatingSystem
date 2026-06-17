; /kernel/sc/sleep.asm
global cmd_sleep, str_sleep

section .data
str_sleep:      db 'sleep', 0
str_sleep_usage: db 'Usage: sleep <ticks>', 13, 10, 0

section .text
cmd_sleep:
    test esi, esi
    jz .usage
    cmp byte [esi], 0
    je .usage

    push esi
    call parse_number
    pop esi

    test eax, eax
    jz .usage

    push eax
    call sleep_ticks
    add esp, 4
    ret

.usage:
    mov esi, str_sleep_usage
    call print_string_32
    ret
