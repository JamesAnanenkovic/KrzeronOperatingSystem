; drivers/memdetect.asm
; Bellek algılama sürücüsü
; Reads memory info stored by bootloader at 0x5000

section .bss
total_ram_kb:   resd 1
total_ram_mb:   resd 1

section .text

global mem_init
mem_init:
    movzx eax, word [0x5000]
    test eax, eax
    jz .fallback
    
    add eax, 1024           ; Total = extended + 1MB base
    mov [total_ram_kb], eax
    shr eax, 10
    mov [total_ram_mb], eax
    clc
    ret

.fallback:
    mov dword [total_ram_kb], 32768
    mov dword [total_ram_mb], 32
    stc
    ret

global mem_get_total_mb
mem_get_total_mb:
    mov eax, [total_ram_mb]
    ret

global mem_get_total_kb
mem_get_total_kb:
    mov eax, [total_ram_kb]
    ret
