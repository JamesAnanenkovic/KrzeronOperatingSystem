; /kernel/idt.asm - IDT, Exception Handlers, PIC

section .data
exception_messages:
    dd msg_div0, msg_debug, msg_nmi, msg_breakpoint
    dd msg_overflow, msg_bound, msg_invop, msg_device
    dd msg_doublef, msg_cpover, msg_invtss, msg_segnp
    dd msg_stack, msg_gpf, msg_pagef, msg_reserved
    dd msg_x87, msg_align, msg_mcheck, msg_simd

msg_div0      db 'Divide by zero', 0
msg_debug     db 'Debug', 0
msg_nmi       db 'Non-maskable interrupt', 0
msg_breakpoint db 'Breakpoint', 0
msg_overflow  db 'Overflow', 0
msg_bound     db 'Bound range exceeded', 0
msg_invop     db 'Invalid opcode', 0
msg_device    db 'Device not available', 0
msg_doublef   db 'Double fault', 0
msg_cpover    db 'Coprocessor segment overrun', 0
msg_invtss    db 'Invalid TSS', 0
msg_segnp     db 'Segment not present', 0
msg_stack     db 'Stack segment fault', 0
msg_gpf       db 'General protection fault', 0
msg_pagef     db 'Page fault', 0
msg_reserved  db 'Reserved exception', 0
msg_x87       db 'x87 FPU error', 0
msg_align     db 'Alignment check', 0
msg_mcheck    db 'Machine check', 0
msg_simd      db 'SIMD exception', 0

msg_exc       db '[KERNEL PANIC] Exception: ', 0
msg_err_code  db ' | Error code: ', 0
msg_cr2_val   db ' | CR2: ', 0
msg_halt      db 13, 10, 'System halted', 0
msg_panic_nl  db 13, 10, 0

section .data
irq_handler_table:
    dd 0, 0, 0, 0, 0, 0, 0, 0
    dd 0, 0, 0, 0, 0, 0, 0, 0

section .bss
align 8
idt_entries:    resb 384                 ; 48 entries * 8 bytes (exceptions + IRQs)
idt_desc:       resb 6                  ; IDT descriptor (2+4 bytes)

section .text

; ============================================================================
; IDT Entry Builder (inline)
; ============================================================================
%macro idt_entry 2
    mov eax, %1                         ; handler address
    mov word [edi], ax                  ; offset low
    mov word [edi+2], 0x08              ; code segment selector
    mov byte [edi+4], 0                 ; IST/reserved
    mov byte [edi+5], %2                ; flags
    shr eax, 16
    mov word [edi+6], ax                ; offset high
    add edi, 8
%endmacro

; ============================================================================
; Exception Handler Stubs
; ============================================================================
%macro isr_noerror 1
isr%1:
    push 0
    push %1
    jmp isr_common
%endmacro

%macro isr_error 1
isr%1:
    push %1
    jmp isr_common
%endmacro

isr_noerror 0
isr_noerror 1
isr_noerror 2
isr_noerror 3
isr_noerror 4
isr_noerror 5
isr_noerror 6
isr_noerror 7
isr_error   8
isr_noerror 9
isr_error   10
isr_error   11
isr_error   12
isr_error   13
isr_error   14
isr_noerror 15
isr_noerror 16
isr_error   17
isr_noerror 18
isr_noerror 19

; ============================================================================
; Common ISR handler
; ============================================================================
isr_common:
    pusha
    push ds
    push es

    mov ax, 0x10
    mov ds, ax
    mov es, ax

    mov esi, msg_exc
    call print_string_32

    mov eax, [esp + 48]                 ; interrupt number
    call print_number_32

    mov esi, msg_panic_nl
    call print_string_32

    ; Print exception name
    mov eax, [esp + 48]
    cmp eax, 19
    ja .unknown
    mov edi, exception_messages
    mov eax, [edi + eax*4]
    mov esi, eax
    call print_string_32

    ; Print error code if present
    mov eax, [esp + 48]
    cmp eax, 8
    je .print_ec
    cmp eax, 10
    je .print_ec
    cmp eax, 11
    je .print_ec
    cmp eax, 12
    je .print_ec
    cmp eax, 13
    je .print_ec
    cmp eax, 14
    je .print_ec
    cmp eax, 17
    je .print_ec
    jmp .check_pagef

.print_ec:
    mov esi, msg_err_code
    call print_string_32
    mov eax, [esp + 52]                 ; error code
    call print_number_32
    jmp .check_pagef

.unknown:
    mov esi, msg_reserved
    call print_string_32

.check_pagef:
    mov eax, [esp + 48]
    cmp eax, 14
    jne .done
    mov esi, msg_cr2_val
    call print_string_32
    mov eax, cr2
    call print_number_32

.done:
    mov esi, msg_halt
    call print_string_32

.hang:
    cli
    hlt
    jmp .hang

; ============================================================================
; IRQ Handler Stubs
; ============================================================================
%macro irq_stub 1
irq%1:
    push %1
    jmp irq_common_handler
%endmacro

irq_stub 0
irq_stub 1
irq_stub 2
irq_stub 3
irq_stub 4
irq_stub 5
irq_stub 6
irq_stub 7
irq_stub 8
irq_stub 9
irq_stub 10
irq_stub 11
irq_stub 12
irq_stub 13
irq_stub 14
irq_stub 15

; ============================================================================
; Common IRQ handler
; ============================================================================
irq_common_handler:
    pusha
    push ds
    push es

    mov ax, 0x10
    mov ds, ax
    mov es, ax

    mov eax, [esp + 40]
    mov edi, irq_handler_table
    mov ebx, [edi + eax*4]
    test ebx, ebx
    jz .eoi

    push eax
    call ebx
    add esp, 4

.eoi:
    mov al, 0x20
    out 0x20, al
    mov eax, [esp + 40]
    cmp eax, 8
    jl .restore
    mov al, 0x20
    out 0xA0, al

.restore:
    pop es
    pop ds
    popa
    add esp, 4
    iret

; ============================================================================
; Register IRQ handler
; ============================================================================
global register_irq_handler
register_irq_handler:
    push ebx
    mov eax, [esp + 8]
    mov ebx, [esp + 12]
    mov [irq_handler_table + eax*4], ebx
    pop ebx
    ret

; ============================================================================
; PIC: unmask IRQ
; ============================================================================
global pic_unmask_irq
pic_unmask_irq:
    push eax
    push ecx
    push edx
    movzx edx, byte [esp + 16]
    cmp dl, 8
    jae .slave
    in al, 0x21
    mov ecx, edx
    mov ebx, 1
    shl ebx, cl
    not ebx
    and al, bl
    out 0x21, al
    jmp .done
.slave:
    sub dl, 8
    in al, 0xA1
    mov ecx, edx
    mov ebx, 1
    shl ebx, cl
    not ebx
    and al, bl
    out 0xA1, al
.done:
    pop edx
    pop ecx
    pop eax
    ret

; ============================================================================
; Initialize IDT
; ============================================================================
global idt_init
idt_init:
    pusha

    mov edi, idt_entries

    ; Exception gates (interrupt gates, ring 0)
    idt_entry isr0,  0x8E
    idt_entry isr1,  0x8E
    idt_entry isr2,  0x8E
    idt_entry isr3,  0x8E
    idt_entry isr4,  0x8E
    idt_entry isr5,  0x8E
    idt_entry isr6,  0x8E
    idt_entry isr7,  0x8E
    idt_entry isr8,  0x8E
    idt_entry isr9,  0x8E
    idt_entry isr10, 0x8E
    idt_entry isr11, 0x8E
    idt_entry isr12, 0x8E
    idt_entry isr13, 0x8E
    idt_entry isr14, 0x8E
    idt_entry isr15, 0x8E
    idt_entry isr16, 0x8E
    idt_entry isr17, 0x8E
    idt_entry isr18, 0x8E
    idt_entry isr19, 0x8E

    ; Skip entries 20-31 (12 unused)
    add edi, 12 * 8

    ; IRQ gates (interrupt gates, ring 0) — entries 32-47
    idt_entry irq0,  0x8E
    idt_entry irq1,  0x8E
    idt_entry irq2,  0x8E
    idt_entry irq3,  0x8E
    idt_entry irq4,  0x8E
    idt_entry irq5,  0x8E
    idt_entry irq6,  0x8E
    idt_entry irq7,  0x8E
    idt_entry irq8,  0x8E
    idt_entry irq9,  0x8E
    idt_entry irq10, 0x8E
    idt_entry irq11, 0x8E
    idt_entry irq12, 0x8E
    idt_entry irq13, 0x8E
    idt_entry irq14, 0x8E
    idt_entry irq15, 0x8E

    ; Set up IDT descriptor
    mov word [idt_desc], 384 - 1        ; limit = 48*8 - 1
    mov eax, idt_entries
    mov [idt_desc+2], eax               ; base

    lidt [idt_desc]

    ; Remap PIC and mask all IRQs
    mov al, 0x11                    ; ICW1: initialize PIC
    out 0x20, al
    out 0xA0, al

    mov al, 0x20                    ; ICW2: master offset = 32
    out 0x21, al
    mov al, 0x28                    ; ICW2: slave offset = 40
    out 0xA1, al

    mov al, 0x04                    ; ICW3: master has slave at IRQ2
    out 0x21, al
    mov al, 0x02                    ; ICW3: slave cascade ID
    out 0xA1, al

    mov al, 0x01                    ; ICW4: x86 mode
    out 0x21, al
    out 0xA1, al

    mov al, 0xFF                    ; Mask all IRQs
    out 0x21, al
    out 0xA1, al

    popa
    ret