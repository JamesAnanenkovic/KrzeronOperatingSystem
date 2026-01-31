; /kernel/sc/read.asm - Experimental disk sector read (ATA PIO LBA28)
global str_read, cmd_read

section .data
str_read:       db 'read', 0
msg_reading:    db 'Reading LBA 0 (boot sector)...', 13, 10, 0
msg_error:      db 'Disk error or timeout', 13, 10, 0
hex_chars:      db '0123456789ABCDEF'

section .bss
align 512
sector_buffer:  resb 512

section .text
cmd_read:
    pusha
    mov esi, msg_reading
    call print_string_32
    
    ; ATA PIO Read (LBA28) - Read sector 0
    mov dx, 0x1F6       ; Drive/Head port
    mov al, 0xA0        ; Master drive, LBA mode
    out dx, al
    
    mov dx, 0x1F2       ; Sector count
    mov al, 1           ; Read 1 sector
    out dx, al
    
    mov dx, 0x1F3       ; LBA low (bits 0-7)
    mov al, 0
    out dx, al
    
    mov dx, 0x1F4       ; LBA mid (bits 8-15)
    mov al, 0
    out dx, al
    
    mov dx, 0x1F5       ; LBA high (bits 16-23)
    mov al, 0
    out dx, al
    
    mov dx, 0x1F7       ; Command port
    mov al, 0x20        ; READ SECTORS
    out dx, al
    
    ; Poll for ready (simple timeout)
    mov ecx, 100000
.poll:
    in al, dx           ; Read status
    test al, 8          ; DRQ bit set?
    jnz .ready
    test al, 1          ; Error bit?
    jnz .error
    loop .poll
    jmp .error          ; Timeout

.ready:
    ; Read 256 words (512 bytes) from data port 0x1F0
    mov dx, 0x1F0
    mov edi, sector_buffer
    mov ecx, 256
    rep insw            ; Read words from DX to [EDI]
    
    ; Hex dump first 16 bytes
    mov esi, sector_buffer
    mov ecx, 16
.dump_loop:
    lodsb
    call print_hex_byte
    mov al, ' '
    call print_char_32
    loop .dump_loop
    
    mov al, 13
    call print_char_32
    mov al, 10
    call print_char_32
    popa
    ret

.error:
    mov esi, msg_error
    call print_string_32
    popa
    ret

print_hex_byte:
    push eax
    push ebx
    movzx ebx, al
    shr bl, 4           ; High nibble
    mov al, [hex_chars + ebx]
    call print_char_32
    
    movzx ebx, al
    and bl, 0x0F        ; Low nibble
    mov al, [hex_chars + ebx]
    call print_char_32
    
    pop ebx
    pop eax
    ret
