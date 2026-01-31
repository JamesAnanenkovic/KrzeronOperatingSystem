; /boot/boot.asm - Diagnostic Bootloader
bits 16
org 0x7C00

KERNEL_SEG      equ 0x1000
SECTORS_TO_LOAD equ 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9000
    sti
    
    mov [boot_drive], dl
    
    ; Clear screen (blue background to show we're alive)
    mov ax, 0x0003
    int 0x10
    
    mov si, msg_start
    call print
    
    ; Reset disk
    xor ah, ah
    int 0x13
    jc disk_error
    
    ; Load kernel
    mov ax, KERNEL_SEG
    mov es, ax
    xor bx, bx
    
    mov ah, 0x02
    mov al, SECTORS_TO_LOAD
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    
    int 0x13
    jc disk_error
    
    mov si, msg_ok
    call print
    
    ; Enable A20 (fast method)
    in al, 0x92
    or al, 2
    out 0x92, al
    
    ; Load GDT
    lgdt [gdt_descriptor]
    
    ; Debug: Turn screen RED before switch (so we know we got here)
    mov ax, 0xB800
    mov es, ax
    mov byte [es:0], 'S'    ; 'S' for Switching
    mov byte [es:1], 0x4F   ; Red background, white text
    
    ; Switch to protected mode
    cli
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    ; Far jump to 32-bit code
    jmp CODE_SEG:protected_mode_32

disk_error:
    mov si, msg_err
    call print
    mov al, ah
    call print_hex
    jmp $

print:
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

print_hex:
    mov bl, al
    shr al, 4
    call .nib
    mov al, bl
    and al, 0x0F
    call .nib
    ret
.nib:
    cmp al, 10
    jl .dig
    add al, 7
.dig:
    add al, '0'
    mov ah, 0x0E
    int 0x10
    ret

; GDT
gdt_start:
    dq 0x0
gdt_code: 
    dw 0xFFFF, 0x0000
    db 0x0, 10011010b, 11001111b, 0x0
gdt_data:
    dw 0xFFFF, 0x0000  
    db 0x0, 10010010b, 11001111b, 0x0
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ 0x08
DATA_SEG equ 0x10

; 32-bit code
bits 32
protected_mode_32:
    ; Set up data segments
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x200000
    
    ; Debug: Turn screen GREEN (shows we entered 32-bit OK)
    ; Writing to VGA directly
    mov edi, 0xB8000
    mov byte [edi], '3'     ; '3' for 32-bit
    mov byte [edi+1], 0x2F  ; Green bg, white fg
    
    ; NOW jump to kernel (0x10000)
    ; Use a far jump to ensure proper transition
    jmp CODE_SEG:0x10000

msg_start   db 'Loading...', 0
msg_ok      db 'OK!', 0
msg_err     db 'Disk err:', 0
boot_drive  db 0

times 510-($-$$) db 0
dw 0xAA55
