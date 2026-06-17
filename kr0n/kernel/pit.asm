; /kernel/pit.asm - PIT driver (IRQ0, 100Hz)

section .data
tick_count:     dd 0

section .text

global pit_init
pit_init:
    pusha

    mov al, 0x36
    out 0x43, al
    mov ax, 11931
    out 0x40, al
    shr ax, 8
    out 0x40, al

    mov eax, pit_handler
    push eax
    push dword 0
    call register_irq_handler
    add esp, 8

    in al, 0x21
    and al, 0xFE
    out 0x21, al

    popa
    ret

pit_handler:
    push eax
    inc dword [tick_count]
    pop eax
    ret

global sleep_ticks
sleep_ticks:
    push ebp
    mov ebp, esp
    push ebx
    mov eax, [ebp + 8]
    mov ebx, [tick_count]
.wait:
    cmp ebx, [tick_count]
    je .wait
    inc ebx
    dec eax
    jnz .wait
    pop ebx
    pop ebp
    ret

global get_tick_count
get_tick_count:
    mov eax, [tick_count]
    ret
