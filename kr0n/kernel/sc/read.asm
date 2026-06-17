; /kernel/sc/read.asm - Disk sector reader (ATA PIO LBA28)
; Usage: read [lba]  — reads one sector, hex-dumps first 16 bytes

global str_read, cmd_read

section .data
str_read:       db 'read', 0
msg_reading:    db 'Reading LBA ', 0
msg_colon:      db ': ', 0
msg_error:      db 13, 10, 'Error reading sector', 13, 10, 0
msg_crlf:       db 13, 10, 0

hex_chars:      db '0123456789ABCDEF'

section .bss
align 512
sector_buffer:  resb 512

section .text
cmd_read:
    pusha

    ; Parse LBA from argument (ESI)
    test esi, esi
    jz .lba0

    push esi
    call parse_number
    pop esi

    ; parse_number returns 0 on either "0" or parse failure.
    ; Check if first char is '0'
    cmp byte [esi], '0'
    je .got_lba
    test eax, eax
    jnz .got_lba
    jmp .lba0

.lba0:
    xor eax, eax

.got_lba:
    push eax                 ; save LBA

    mov esi, msg_reading
    call print_string_32
    pop eax
    push eax
    call print_number_32
    mov esi, msg_colon
    call print_string_32

    pop eax
    push eax

    mov edi, sector_buffer
    mov ecx, 1
    call ata_read_sectors
    jc .error

    ; Hex dump first 16 bytes
    mov esi, sector_buffer
    mov ecx, 16
.dump:
    lodsb
    call print_hex_byte
    mov al, ' '
    call print_char_32
    loop .dump

    mov esi, msg_crlf
    call print_string_32
    jmp .done

.error:
    mov esi, msg_error
    call print_string_32

.done:
    pop eax                  ; discard LBA
    popa
    ret

print_hex_byte:
    push eax
    push ebx

    movzx ebx, al
    shr bl, 4
    mov al, [hex_chars + ebx]
    call print_char_32

    movzx ebx, byte [esp + 4]    ; original al from saved eax
    and bl, 0x0F
    mov al, [hex_chars + ebx]
    call print_char_32

    pop ebx
    pop eax
    ret
