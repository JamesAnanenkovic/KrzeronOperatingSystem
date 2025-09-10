; Kr0nos Bootloader - Pure Assembly
bits 16
org 0x7C00

; Constants
STACK_TOP      equ 0x7C00
KERNEL_OFFSET  equ 0x1000

start:
    ; Set up segment registers
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, STACK_TOP
    sti

    ; Save boot drive
    mov [boot_drive], dl

    ; Clear screen
    mov ax, 0x0003  ; 80x25 text mode
    int 0x10

    ; Print welcome message
    mov si, welcome_msg
    call print_string

    ; Load kernel from disk
    mov bx, KERNEL_OFFSET
    mov es, bx      ; ES:BX = 0x1000:0x0000
    xor bx, bx
    
    mov ah, 0x02    ; Read sectors
    mov al, 8       ; Number of sectors to read (4KB)
    mov ch, 0       ; Cylinder 0
    mov cl, 2       ; Sector 2 (1-based)
    mov dh, 0       ; Head 0
    mov dl, [boot_drive]
    
    ; Try to read disk
    int 0x13
    jc disk_error   ; If carry flag is set, there was an error
    
    ; Check if any sectors were read
    cmp al, 0
    je disk_error
    
    ; Print success message
    mov si, load_success_msg
    call print_string
    
    ; Jump to kernel
    jmp KERNEL_OFFSET:0x0000

; Print string (null-terminated)
; DS:SI = string address
print_string:
    pusha
    mov ah, 0x0E        ; BIOS teletype function
    xor bx, bx          ; Page 0

.print_loop:
    lodsb               ; Load next character
    or al, al           ; Check for null terminator
    jz .done
    int 0x10            ; Print character
    jmp .print_loop

.done:
    popa
    ret

; Print hex digit in AL
print_hex_digit:
    pusha
    and al, 0x0F
    cmp al, 10
    jl .is_digit
    add al, 7        ; Adjust for A-F
.is_digit:
    add al, '0'
    mov ah, 0x0E
    int 0x10
    popa
    ret

disk_error:
    mov si, disk_error_msg
    call print_string
    
    ; Print error code in AH
    mov al, ah
    call print_hex_digit
    
    ; Halt
    cli
    hlt
    jmp $

; Data
welcome_msg      db 'Kr0nos OS Booting...', 0x0D, 0x0A, 0
load_success_msg db 'Kernel loaded successfully!', 0x0D, 0x0A, 0
disk_error_msg   db 'Disk error: ', 0
boot_drive       db 0

; Boot signature
times 510-($-$$) db 0
dw 0xAA55
