; /kernel/sc/exit.asm - ACPI shutdown (works in 32-bit)
global str_exit, cmd_exit

section .data
str_exit:       db 'exit', 0
shutdown_msg:   db 'Shutting down...', 13, 10, 0

section .text
cmd_exit:
    pusha
    mov esi, shutdown_msg
    call print_string_32
    
    ; QEMU/VirtualBox ACPI shutdown port
    mov dx, 0x604
    mov ax, 0x2000
    out dx, ax              ; 16-bit write to port 0x604
    
    ; Fallback halt if ACPI didn't work (real hardware)
    cli
.hang:
    hlt
    jmp .hang
